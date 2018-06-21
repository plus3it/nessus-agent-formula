{%- from tpldir ~ '/map.jinja' import nessus with context %}

# This sls file will install the Nessus agent and assumes that
# the required Nessus server configurations will be provided in the
# pillar configuration.
# In addiont, the sls file requires that the salt winrepo has been
# configured with a `nessus agent` pkg definition

{%- if nessus.log_rotation_strategy %}
Add Log Rotation Strategy:
  file.replace:
    - name: C:\ProgramData\Tenable\Nessus Agent\nessus\log.json
    - pattern: '"file": "c:\\\\ProgramData\\\\Tenable\\\\Nessus Agent\\\\nessus\\\\logs\\\\www_server.log"'
    - repl: '"rotation_strategy": "{{nessus.log_rotation_strategy}}",\n                \g<0>'
    - watch:
      - pkg: install-nessus-agent
{%- endif %}

{%- if nessus.log_rotation_time %}
Add Log Rotation Time:
  file.replace:
    - name: C:\ProgramData\Tenable\Nessus Agent\nessus\log.json
    - pattern: '"file": "c:\\\\ProgramData\\\\Tenable\\\\Nessus Agent\\\\nessus\\\\logs\\\\www_server.log"'
    - repl: '"rotation_time": "{{nessus.log_rotation_time}}",\n                \g<0>'
    - watch:
      - pkg: install-nessus-agent
{%- endif %}

{%- if nessus.log_max_size %}
Add Log Max Size:
  file.replace:
    - name: C:\ProgramData\Tenable\Nessus Agent\nessus\log.json
    - pattern: '"file": "c:\\\\ProgramData\\\\Tenable\\\\Nessus Agent\\\\nessus\\\\logs\\\\www_server.log"'
    - repl: '"max_size": "{{nessus.log_max_size}}",\n                \g<0>'
    - watch:
      - pkg: install-nessus-agent
{%- endif %}

{%- if nessus.log_max_files %}
Add Log Max Files:
  file.replace:
    - name: C:\ProgramData\Tenable\Nessus Agent\nessus\log.json
    - pattern: '"file": "c:\\\\ProgramData\\\\Tenable\\\\Nessus Agent\\\\nessus\\\\logs\\\\www_server.log"'
    - repl: '"max_files": "{{nessus.log_max_files}}",\n                \g<0>'
    - watch:
      - pkg: install-nessus-agent
{%- endif %}

install-nessus-agent:
  pkg.installed:
    - name: {{ nessus.package }}
{%- if nessus.version %}
    - version: {{ nessus.version }}
{%- endif %}
    - allow_updates: True
