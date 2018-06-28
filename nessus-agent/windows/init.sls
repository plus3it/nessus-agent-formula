{%- from tpldir ~ '/map.jinja' import nessus with context %}

# This sls file will install the Nessus agent and assumes that
# the required Nessus server configurations will be provided in the
# pillar configuration.
# In addiont, the sls file requires that the salt winrepo has been
# configured with a `nessus agent` pkg definition

{%- for log_file,log_rotation in nessus.log_config.items() %}
  {%- for rotation_param,rotation_value in log_rotation.items() %}
Add Log Config {{ log_file }} {{ rotation_param }}:
  file.replace:
    - name: C:\ProgramData\Tenable\Nessus Agent\nessus\log.json
    - pattern: '"file": "{{ log_file }}"'
    - repl: '"{{ rotation_param }}": "{{ rotation_value }}",\n                \g<0>'
    - watch:
      - pkg: install-nessus-agent
  {%- endfor %}
{%- endfor %}

install-nessus-agent:
  pkg.installed:
    - name: {{ nessus.package }}
{%- if nessus.version %}
    - version: {{ nessus.version }}
{%- endif %}
    - allow_updates: True
