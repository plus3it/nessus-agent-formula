{%- set os_family = salt['grains.get']('os_family') %}

{%- if os_family == 'Windows' %}

include:
  - .windows

{%- else %}

include:
  - .elx

{%- endif %}
