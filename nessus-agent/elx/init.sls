#
# This salt state installs the Nessus Agent using the provided
# URL to the rpm source file.  Once installed, the agent will be
# configured and linked to the Nessus server using the provided
# parameters (Nessus 64 hexadecimal-digit key, Nessus server FQDN and
# port, Nessus Agent Group Name).  The final step is to start tHe
# Nessus Agent service.
#################################################################
{%- from tpldir ~ '/map.jinja' import nessus with context %}

include:
  - nessus-agent.elx.install
  - nessus-agent.elx.configure
