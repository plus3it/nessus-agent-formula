{%- from tpldir ~ '/map.jinja' import nessus with context %}

# This sls file will install the Nessus agent and assumes that
# the required Nessus server configurations will provided in the
# pillar configuration.
# In addiont, the sls file requires that the salt winrepo has been
# configured with a `nessus` pkg definition

install-nessus-agent:
  pkg.installed:
    - name: {{ nessus.package }}
{%- if nessus.version %}
    - version: {{ nessus.version }}
{%- endif %}
    - allow_updates: True
