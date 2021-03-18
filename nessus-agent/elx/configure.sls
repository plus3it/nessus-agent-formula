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
      - pkg: '{{ nessus.package }}'
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

Start Nessus Agent:
  service.running:
    - name: {{ nessus.package | lower }}
    - enable: True
    - require:
      - cmd: Configure Nessus Agent
