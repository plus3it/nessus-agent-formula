# Background

Some recent (started receiving reports in late 2025) users of this formula have reported that, after this formula has installed and configured their Nessus Agents on hosts, they get scan-failures on their Linux hosts. When they check their Nessus servers' logs, they find error-log entries indicating that the failures are due to storage-space exhaustion.

Initial investigation of this issue found that what was happening was that the storage-space problem was a result of the scan process installing plugins. The initial issue was exhaustion caused by the scanner staging and then attempting to unarchive to-be-installed plugins in the `/opt/nessus_agent/var/tmp` directory. Attempts to forestall this problem via updates to this project's automation solved _that_ problem. However, it didn't solve the overarching space-exhaustion issues.

Further testing showed that fixing the inital probelem caused by the `/opt/nessus_agent/var/tmp` directory filling up then resulted in the `/opt/nessus_agent/var/nessus/` directory filling up. Initially, it was assumed that this was due to the _plugins_ successful installation. However, these plugins only accounted for a further 10MiB of space-consumption (in the `/opt/nessus_agent/var/nessus//plugins` subdirectory). Once a scan started to run, it begins to generate a collection of `*.db` and `*.db-*` files (directly) within the `/opt/nessus_agent/var/nessus/` directory. On a testing-system with the `/` filesystem over-provisioned (in testing, grew the `/` filesystem by 10GiB), it was found that the _first_ successful scan of a system resulted in just shy of 1.8GiB of persistent `*.db` and `*.db-*` files being created.

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

The most-frequently observed method for implementing multiple filesystem on Enterprise Linux hosts is via LVM2. The following guidance assumes the use of LVM2 for the paritioning of the boot-disk and that the `/` filesystem is hosted on an LVM2 volume.

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
# UserData script to set up SSM and console-based access
#
#################################################################

lvextend -rl +100%FREE RootVG/rootVol

--===============BOUNDARY==--
```

The above userData will

1. Attempt to grow the disk-partition known to the system as `/dev/nvme0n1p4`.
2. Attempt to grow the LVM2 volume-object (that lives on the `/dev/nvme0n1p4` blocke-device node)

If multpart-MIME is undesirable, the `cloud-config` block can be removed and its logic:

```
growpart /dev/nvme0n1 4
```

Incormporated in the BASH block _before_ the `lvextend` operation. The multipart-MIME is somewhat more-appropriate when pursuing a more-flexible approach to the problem.

### `/opt` Hosted On A Standalone Filesystem

[^1]: The userData-payload shown is _very_ simplified and not very flexible as a result. Flexibility can be achieved by using "discovery" logic to determing things like the name of LVM2 volume-group and volume-name associated with the `/` filesystem.

