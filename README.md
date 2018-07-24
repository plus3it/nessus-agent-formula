# nessus-agent-formula

This Salt formula will install the Nessus Agent and, if all Nessus server parameters
are provided, will also link the agent to the server.  This formula supports
both Windows and Linux.

On Windows, the formula depends on the Salt Windows Package Manager (`winrepo`),
and a `winrepo` package definition must be present for the Nessus Agent.
Configuring `winrepo` is not handled by this formula.

## Available States

-   [nessus-agent](#nessus-agent)

### nessus-agent

Installs the Nessus Agent.

## Windows Configuration

This formula supports configuration via pillar for the name of the winrepo
package and the version of the package to install. All settings must be
located within the `nessus-agent:lookup` pillar dictionary.

### `nessus-agent:lookup:package`

The `package` parameter is the name of the package as defined in the winrepo
package definition.

>**Required**: `False`
>
>**Default**: `nessus-agent`

**Example**:

```yaml
nessus-agent:
  lookup:
    package: nessus-agent
```

### `nessus-agent:lookup:version`

The `version` parameter is the version of the package as defined in the
winrepo package definition.

>**Required**: `False`
>
>**Default**: `''`

**Example**:

```yaml
nessus-agent:
  lookup:
    version: '7.0.3.1354'
```

## Linux Configuration

The only _required_ configuration setting for Linux systems is the source URL
to the Nessus Agent rpm. There are additional parameters described below,
that are needed to link the agent to a central Nessus management server.
All settings must be located within the `nessus-agent:lookup` pillar dictionary.

### `nessus-agent:lookup:package_url`

The `package_url` parameter is the URL to the Nessus Agent rpm.

>**Required**: `True`
>
>**Default**: `None`

**Example**:

```yaml
nessus-agent:
  lookup:
    package_url: https://S3BUCKET.F.Q.D.N/nessus-agent/NessusAgent-7.0.3-es7.x86_64.rpm
```

### `nessus-agent:lookup:nessus_server`

The `nessus_server` parameter is the FQDN of a Nessus management server.

>**Required**: `False`
>
>**Default**: `''`

**Example**:

```yaml
nessus-agent:
  lookup:
    nessus_server: 'nessus.server.com'
```

### `nessus-agent:lookup:nessus_key`

The `nessus_key` parameter is 64 hexadecimal-digit key to the Nessus management server .

>**Required**: `False`
>
>**Default**: `''`

**Example**:

```yaml
nessus-agent:
  lookup:
    nessus_key: '0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff'
```

### `nessus-agent:lookup:nessus_port`

The `nessus_port` parameter is the port number to access the Nessus management server .

>**Required**: `False`
>
>**Default**: `''`

**Example**:

```yaml
nessus-agent:
  lookup:
    nessus_port: '8843'
```

### `nessus-agent:lookup:nessus_groups`

The `nessus_groups` parameter is a group name where the Nessus agent will be assigned.

>**Required**: `False`
>
>**Default**: `''`

**Example**:

```yaml
nessus-agent:
  lookup:
    nessus_groups: 'NessusAgents'
```

## Logging Configuration

There is an option to configure a custom log retention policy for each log file that
is available within the Nessus Agent.  The `log.json` file contains definitions for
the reporters which define the log files and logging formats.

The `log.json` is located in the following directories:

Linux:  `/opt/nessus_agent/var/nessus/log.json`

Windows:  `C:\ProgramData\Tenable\Nessus Agent\nessus\log.json`

Changing the default log retention policy can be done by modifying the `log.json`
file and adding the following parameters to each reporter definition:

-   Rotation Strategy
-   Rotation Time
-   Max Size
-   Max Files

The logging configuration is _optional_ and is not required as part of the Nessus Agent
installation.

For more information, please refer to the vendor documentation:

[How to Manage Nessus log size and rotation](https://community.tenable.com/s/article/How-to-manage-Nessus-log-size-and-rotation)

To configure a custom log retention policy, the parameters must be added to the
`nessus-agent:lookup` pillar definition in the following structure:

```yaml
nessus-agent:
  lookup:
    log_config:
      <file-path-to-log-file>:
        rotation_strategy: ''
        rotation_size: ''
        max_size: ''
        max_files: ''
```

### `nessus-agent:lookup:log_config`

`log_config` is the main heading that begins the logging configuration.

### `nessus-agent:lookup:log_config:<file-path-to-log-file>`

`<file-path-to-log-file>` identifies the log file path that is present in the
`log.json` reporter definitions.

Add additional `<file-path-to-log-file>` sections to the pillar, if desired, for
other reporters present within `log.json`.

A reporter containing the log file path must be present in `log.json` or
the logging configurations will not be added.  Adding additional reporters to
`log.json` is outside the scope of the Nessus Agent Salt formula.

### `nessus-agent:lookup:<file-path-to-log-file>:rotation_strategy`

The `rotation_strategy` parameter can be set to `daily` or `size`.

### `nessus-agent:lookup:<file-path-to-log-file>:rotation_time`

The `rotation_time` parameter is the rotation time in `seconds`.  Used when
`rotation_strategy` is set to `daily`.

### `nessus-agent:lookup:<file-path-to-log-file>:max_size`

The `max_size` parameter is the rotation size in `bytes`.  Used when
`rotation_strategy` is set to `size`.

### `nessus-agent:lookup:<file-path-to-log-file>:max_files`

The `max_files` parameter is the maximum number of files retained in the file
rotation.  Used whether `rotation_strategy` is set to `daily` or `size`.

### **Example (Linux)**:

```yaml
nessus-agent:
  lookup:
    log_config:
      /opt/nessus_agent/var/nessus/logs/www_server.log:
        rotation_strategy: 'size'
        max_size: '268435456'
        max_files: '512'
```

### **Example (Windows)**:

```yaml
nessus-agent:
  lookup:
    log_config:
      c:\\\\ProgramData\\\\Tenable\\\\Nessus Agent\\\\nessus\\\\logs\\\\www_server.log:
        rotation_strategy: 'daily'
        rotation_time: '86400'
        max_files: '1024'
```
