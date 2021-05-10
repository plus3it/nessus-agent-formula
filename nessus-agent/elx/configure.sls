# This salt state configures a previously-installed Nessus Agent -
# whether baked-in or installed by the 'install' component of this
# formula. The agent will be configured and linked to the Nessus server
# using the provided parameters (Nessus 64 hexadecimal-digit key,
# Nessus server FQDN and port, Nessus Agent Group Name). The final step
# is to start the Nessus Agent service.
#
###########################################################################
{%- from tpldir ~ '/map.jinja' import nessus with context %}
{%- set chkFile = '/etc/tenable_tag' %}
{%- set staleDbs = salt.file.find('/opt/nessus_agent/var/nessus/', maxdepth=1, type='f', name='*.db') %}
{%- set linkStr =
        nessus.sbin_file ~
        ' agent link --key=' ~ nessus.nessus_key ~
        ' --host=' ~ nessus.nessus_server ~
        ' --port=' ~ nessus.nessus_port ~
        ' --groups=' ~ nessus.nessus_groups
%}

{%- if staleDbs %}
Unlink Stale Agent-config:
  cmd.run:
    - name: '{{ nessus.sbin_file }} agent unlink'
    - success_retcodes:
      - 0
      - 2

Stop Nessus Agent:
  service.dead:
    - name: {{ nessus.package | lower }}
    - require:
      - cmd: Unlink Stale Agent-config

  {%- for staleDb in staleDbs %}
Nuke Stale {{ staleDb }} file:
  file.absent:
    - name: '{{ staleDb }}'
    - require:
      - Stop Nessus Agent
    - require_in:
      - Configure Nessus Agent
  {%- endfor %}
{%- endif %}

Handle {{ chkFile }} file:
  file.absent:
    - name: '{{ chkFile }}'

Configure Nessus Agent:
  cmd.run:
    - name: {{ linkStr }}
    - require:
      - file: Handle {{ chkFile }} file

Start Nessus Agent:
  service.running:
    - name: {{ nessus.package | lower }}
    - enable: True
    - require:
      - cmd: Configure Nessus Agent
