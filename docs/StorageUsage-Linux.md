# Background

Some recent (started receiving reports in late 2025) users of this formula have reported that, after this formula has installed and configured their Nessus Agents on hosts, they get scan-failures on their Linux hosts. When they check their Nessus servers' logs, they find error-log entries indicating that the failures are due to storage-space exhaustion.

Initial investigation of this issue found that what was happening was that the storage-space problem was a result of the scan process installing plugins. The initial issue was exhaustion caused by the scanner staging and then attempting to unarchive to-be-installed plugins in the `/opt/nessus_agent/var/tmp` directory. Attempts to forestall this problem via updates to this project's automation solved _that_ problem. However, it didn't solve the overarching space-exhaustion issues.

Further testing showed that fixing the initial problem caused by the `/opt/nessus_agent/var/tmp` directory filling up then resulted in the `/opt/nessus_agent/var/nessus/` directory filling up. Initially, it was assumed that this was due to the _plugins_ successful installation. However, these plugins only accounted for a further 10MiB of space-consumption (in the `/opt/nessus_agent/var/nessus//plugins` subdirectory). Once a scan started to run, it begins to generate a collection of `*.db` and `*.db-*` files (directly) within the `/opt/nessus_agent/var/nessus/` directory. On a testing-system with the `/` filesystem over-provisioned (in testing, grew the `/` filesystem by 10GiB), it was found that the _first_ successful scan of a system resulted in just shy of 1.8GiB of persistent `*.db` and `*.db-*` files being created.

# Configurations Susceptible to the Problem

This problem only afflicts:

* Single-partition systems where the `/` filesystem has less than 2GiB of free storage prior to the initiation of scanning
* Partitioned systems where the `/opt` filesystem &mdash; or, more typically, an `/opt`-hosting `/` filesystem &mdash; has less than 2GiB of free storage prior to the initiation of scanning

The former is typical of EC2s launched from community Enterprise Linux AMIs or similar images published via the AWS Marketplace. Similar is assumed would happen within other template-driven deployments, particular in public CSPs (Azure, GCP, etc.) but has not been directly observed by this project's maintainers.

# Suggested Fixes/Workarounds

## Single-partition Systems

With typical, cloud-hosted OS image-templates, the `cloud-init` utility is installed. If present, the fix is as simple as increasing the size of the boot-volume by at least 2GiB. The `cloud-init` utility will typically just automatically expand the `/` filesystem onto the additional storage.

For systems without the `cloud-init` utility installed, it will be necessary to update provisioning processes (e.g. Ansible-based system-configuration) to grow the `/`-hosting partition and expand the `/` filesystem to match the resized partition. Typically, this requires using some combination of the `growpart` utility and the filesystem-utilities for the `/` filesystem's fs-type. Most commonly, the `/` filesystem on Enterprise Linux systems is XFS. If this is the case for your Enterprise Linux operating system, that will mean the use of the `xfs_growfs` utility. Usage of the relevant utilities is outside the scope of this document

## Multi-Partition Systems

The most-frequently observed method for implementing multiple filesystems on Enterprise Linux hosts is via LVM2. The following guidance assumes the use of LVM2 for the partitioning of the boot-disk and that the `/` filesystem is hosted on an LVM2 volume.

### `/opt` Hosted Within the `/` Filesystem

It is assumed that
* The `/` filesystem is hosted on an LVM2 volume object
* The system-provisioner has extended their LVM2-hosting boot-disk by at least 2GiB
* That the boot LVM2 volume-group is named `RootVG` and the volume hosting the `/` partition is named `rootVol`

Fixing this configuration requires knowing:

* The device-path of the block-device hosting the LVM2 volume-group
* The name of the LVM2 volume-group hosting the root volumes and filesystems
* The name of logical volume hosting the `filesystem`.

While it's not _strictly_ necessary to know these values, _not_ knowing them considerably increases the complexity of the necessary userData payload[^1].

With the `cloud-init` utility present in the host operating system, the problem can be prevented with a mixed-MIME userData payload. Adjust the following userData payload to reflect your host's _actual_ LVM2 volume-group name, name of the volume hosting the `/` parition and the device-path of the block-device hosting the root filesystem(s):


```
Content-Type: multipart/mixed; boundary="===============BOUNDARY=="
MIME-Version: 1.0
Number-Attachments: 2

--===============BOUNDARY==
Content-Disposition: attachment; filename="cloud.cfg"
Content-Transfer-Encoding: 7bit
Content-Type: text/cloud-config
Mime-Version: 1.0

#cloud-config

# Ensure that we use any available extra storage
growpart:
  mode: auto
  devices: [
      '/dev/nvme0n1p4'
    ]


--===============BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript
Content-Disposition: attachment; filename="00_bootdev_setup.sh"
#!/bin/bash
set -euo pipefail
#
# UserData scriptlet to extent rootVol LVM2 volume
#
#################################################################

lvextend -rl +100%FREE RootVG/rootVol

--===============BOUNDARY==--
```

The above userData will

1. Attempt to grow the disk-partition known to the system as `/dev/nvme0n1p4`.
2. Attempt to grow the LVM2 volume-object (that lives on the `/dev/nvme0n1p4` block-device node).

If multipart-MIME[^2] is undesirable[^3], the `cloud-config` block can be removed and its logic reimplemented like:

```
growpart /dev/nvme0n1 4
```

In the BASH block _before_ the `lvextend` operation. The multipart-MIME is somewhat more-appropriate when pursuing a more-flexible and/or modular approach to the problem.

### `/opt` Hosted On A Standalone Filesystem

This solution is basically the same as the "`/opt` Hosted Within the `/` Filesystem" solution. However, it assumes that the `/opt` filesystem already exists as a separate filesystem and associated LVM2 volume. Substitute values from the `/` filesystem solution as appropriate.

### Moving `/opt/nessus_agent` To Its Own filesystem

This section assumes that the boot-disk has already been expanded and the partition hosting the LVM2 volume-group has been grown.

While the entire `/opt` filesystem _could_ be divorced from the `/` filesystem, the `/opt` filesystem typically already has content within it. Further, that content often results in open file-handles that make launch-time automation more problematic to account for. To ensure that _just_ the `/opt/nessus_agent` content ends up on a dedicated partition, userData payload similar to:

```
[...ELIDED...]

--===============BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript
Content-Disposition: attachment; filename="01_nessusdev_setup.sh"
#!/bin/bash
set -euo pipefail
#
# UserData scriptlet create a dedicated LVM volume mount for the
# Nessus agent
#
#################################################################

lvcreate -L <SIZE_OF_VOLUME> -n nessusVol RootVG
mkfs -t xfs -L NessusAgent /dev/RootVG/nessusVol
install -dDm 0700 /opt/nessus_agent
print -f '/dev/RootVG/nessusVol\t/opt/nessus_agent\txfs\tdefaults\t1 1\n' >> /etc/fstab
systemctl daemon-reload
mount /dev/RootVG/nessusVol

--===============BOUNDARY==--
```

Can be used. The above:

1. Creates an LVM2 volume named "`nessusVol`" within the "`RootVG`" LVM2 volume-group
1. Creates an XFS filesystem, with the "`NessusAgent`" label, on top of the "`nessusVol`" LVM2 volume
1. Creates the mountpoint, "`/opt/nessus_agent`"
1. Adds a suitable entry to the system's "`/etc/fstab`" file
1. Makes `systemd` reread the "`/etc/fstab`" file to update its mount-unit definitions
1. Mounts the XFS-formatted filesystem hosted on "`/dev/RootVG/nessusVol`" to the "`/opt/nessus_agent`" mountpoint

[^1]: The userData-payload shown is _very_ simplified and not very flexible as a result. Flexibility can be achieved by using "discovery" logic to determine things like the name of LVM2 volume-group and volume-name associated with the `/` filesystem.
[^2]: It is assumed that this formula would be run via a block where the `filename` value causes it to be executed after all prior blocks. For example, something like `filename=99_runwam.sh`. See the [watchmaker documentation](https://watchmaker.readthedocs.io/en/stable/usage.html#linux) for ideas on contents for the block.
[^3]: Multipart-MIME is recommended as it allows the easy, modular setup of launch-time automation. Different automation-chunks can be logically grouped and, by the use of suitable `filename` values, execution-order can be enforced
