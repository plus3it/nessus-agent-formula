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

### `nessus-agent:lookup:package_url_es6`

The `package_url_es6` parameter is the URL to a EL6 Nessus Agent rpm.

>**Required**: `True`
>
>**Default**: `None`

**Example**:

```yaml
nessus-agent:
  lookup:
    package_url_es6: https://S3BUCKET.F.Q.D.N/nessus-agent/NessusAgent-7.0.3-es6.x86_64.rpm
```

### `nessus-agent:lookup:package_url_es7`

The `package_url_es7` parameter is the URL to a EL7 Nessus Agent rpm.

>**Required**: `True`
>
>**Default**: `None`

**Example**:

```yaml
nessus-agent:
  lookup:
    package_url_es7: https://S3BUCKET.F.Q.D.N/nessus-agent/NessusAgent-7.0.3-es7.x86_64.rpm
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

Common to both Windows and Linux are the parameters to configure the logging
rotation and size.  To apply these settings, add them to the `nessus-agent:lookup`
pillar dictionary.  These parameters are _optional_ and are not required to be
configured in the pillar dictionary.

The rotation and size of the logging system can be controlled by setting the following
parameters:

-   [Rotation Strategy](#nessus-agentlookuplog_rotation_strategy)
-   [Rotation Time](#nessus-agentlookuplog_rotation_time)
-   [Max Size](#nessus-agentlookuplog_max_size)
-   [Max Files](#nessus-agentlookuplog_max_files)

For more information, please refer to vendor documentation:

[How to Manage Nessus log size and rotation](https://community.tenable.com/s/article/How-to-manage-Nessus-log-size-and-rotation)

### `nessus-agent:lookup:log_rotation_strategy`

The `log_rotation_strategy` parameter can be set to `daily` or `size`.

**Required**: `False`
>
>**Default**: ``

**Example**:

```yaml
nessus-agent:
  lookup:
    log_rotation_strategy: 'daily'
```

### `nessus-agent:lookup:log_rotation_time`

The `log_rotation_time` parameter is the rotation time in `seconds`.  Used when `log_rotation_strategy` is set to `"daily"`.

**Required**: `False`
>
>**Default**: ``

**Example**:

```yaml
nessus-agent:
  lookup:
    log_rotation_time: '86400'
```

### `nessus-agent:lookup:log_max_size`

The `log_max_size` parameter is the rotation size in `bytes`.  Used when `log_rotation_strategy` is set to `"size"`.

**Required**: `False`
>
>**Default**: ``

**Example**:

```yaml
nessus-agent:
  lookup:
    log_max_size: '134217728'
```

### `nessus-agent:lookup:log_max_files`

The `log_max_files` parameter is the maximum number of files allowed.

**Required**: `False`
>
>**Default**: ``

**Example**:

```yaml
nessus-agent:
  lookup:
    log_max_files: '256'
```
