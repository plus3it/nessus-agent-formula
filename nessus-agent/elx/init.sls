#
# This salt state installs the Nessus Agent using the provided
# URL to the rpm source file.  Once installed, the agent will be
# configured and linked to the Nessus server using the provided
# parameters (Nessus 64 hexadecimal-digit key, Nessus server FQDN and
# port, Nessus Agent Group Name).  The final step is to start tHe
# Nessus Agent service.
#################################################################
{%- from tpldir ~ '/map.jinja' import nessus with context %}

{%- if (nessus.nessus_key and nessus.nessus_server and nessus.nessus_port and nessus.nessus_groups) %}
Configure Nessus Agent:
  cmd.run:
    - name: {{ nessus.sbin_file }} agent link --key={{ nessus.nessus_key }} --host={{ nessus.nessus_server }} --port={{ nessus.nessus_port }} --groups={{ nessus.nessus_groups }}
    - require:
      - pkg: Install Nessus Package
{%- else %}
Print nessus-agent help:
  test.show_notification:
    - text: |
        The nessus-agent installation requires the following parameters to
        complete the integration of the agent with the server:

          nessus_key
          nessus_server
          nessus_port
          nessus_groups

        If all parameters are not available, the nessus-agent will be installed
        without linking the agent to the server.
{%- endif %}

{%- for log_file,log_rotation in nessus.log_config.items() %}
  {%- for rotation_param,rotation_value in log_rotation.items() %}
Add Log Config {{ log_file }} {{ rotation_param }}:
  file.replace:
    - name: /opt/nessus_agent/var/nessus/log.json
    - pattern: '"file": "{{ log_file }}"'
    - repl: '"{{ rotation_param }}": "{{ rotation_value }}",\n                \g<0>'
    - watch:
      - cmd: Pause For Log File
  {%- endfor %}
{%- endfor %}

Pause For Log File:
  cmd.run:
    - name: sleep 5
    - watch:
      - cmd: Start Nessus Agent

Pre-Create Nessus Log Directory:
  file.directory:
    - name: /var/log/nessus/logs
    - user: root
    - group: root
    - dir_mode: 0755
    - recurse:
      - user
      - group
      - mode
    - makedirs: True

Create Sym-link To Log Dir:
  file.symlink:
    - name: /opt/nessus_agent/var/nessus/logs
    - target: /var/log/nessus/logs
    - user: root
    - group: root
    - mode: 0755
    - makedirs: True
    - require:
      - file: Pre-Create Nessus Log Directory

Start Nessus Agent:
  cmd.run:
    - name: /sbin/service nessusagent start
    - require:
      - pkg: Install Nessus Package

Install Nessus Package:
  pkg.installed:
    - sources:
      - {{ nessus.package }}: {{ nessus.package_url }}
    - require:
      - file: Create Sym-link To Log Dir
