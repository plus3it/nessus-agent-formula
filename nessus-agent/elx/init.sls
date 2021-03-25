# This salt state invokes further salt states to install and configure
# the Nessus Agent using the provided 'install' and 'configure' states
# to do the heavy-lifting
#
###########################################################################
{%- from tpldir ~ '/map.jinja' import nessus with context %}

include:
  - nessus-agent.elx.install
  - nessus-agent.elx.configure
