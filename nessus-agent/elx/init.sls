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

{%- if nessus.log_rotation_strategy %}
Add Log Rotation Strategy:
  file.replace:
    - name: /opt/nessus_agent/var/nessus/log.json
    - pattern: '"file": "/opt/nessus_agent/var/nessus/logs/www_server.log"'
    - repl: '"rotation_strategy": "{{nessus.log_rotation_strategy}}",\n                \g<0>'
    - watch:
      - cmd: Pause For Log File
{%- endif %}

{%- if nessus.log_rotation_time %}
Add Log Rotation Time:
  file.replace:
    - name: /opt/nessus_agent/var/nessus/log.json
    - pattern: '"file": "/opt/nessus_agent/var/nessus/logs/www_server.log"'
    - repl: '"rotation_time": "{{nessus.log_rotation_time}}",\n                \g<0>'
    - watch:
      - cmd: Pause For Log File
{%- endif %}

{%- if nessus.log_max_size %}
Add Log Max Size:
  file.replace:
    - name: /opt/nessus_agent/var/nessus/log.json
    - pattern: '"file": "/opt/nessus_agent/var/nessus/logs/www_server.log"'
    - repl: '"max_size": "{{nessus.log_max_size}}",\n                \g<0>'
    - watch:
      - cmd: Pause For Log File
{%- endif %}

{%- if nessus.log_max_files %}
Add Log Max Files:
  file.replace:
    - name: /opt/nessus_agent/var/nessus/log.json
    - pattern: '"file": "/opt/nessus_agent/var/nessus/logs/www_server.log"'
    - repl: '"max_files": "{{nessus.log_max_files}}",\n                \g<0>'
    - watch:
      - cmd: Pause For Log File
{%- endif %}

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
{%- if salt.grains.get('osmajorrelease') == '7'%}
      - {{ nessus.package }}: {{ nessus.package_url_es7 }}
{%- elif salt.grains.get('osmajorrelease') == '6'%}
      - {{ nessus.package }}: {{ nessus.package_url_es6 }}
{%- endif %}
    - require:
      - file: Create Sym-link To Log Dir
