# This salt state installs the Nessus Agent using the provided
# URL to the rpm source file.
#
#################################################################
{%- from tpldir ~ '/map.jinja' import nessus with context %}
{%- set nessus_root = '/opt/nessus_agent'%}
{%- set real_nessus_log = '/var/log/nessus/logs' %}
{%- set real_nessus_tmp = '/var/tmp/nessus' %}

{%- for log_file,log_rotation in nessus.log_config.items() %}
  {%- for rotation_param,rotation_value in log_rotation.items() %}
Add Log Config {{ log_file }} {{ rotation_param }}:
  file.replace:
    - name: '{{ nessus_root }}/var/nessus/log.json'
    - pattern: '"file": "{{ log_file }}"'
    - repl: '"{{ rotation_param }}": "{{ rotation_value }}",\n                \g<0>'
    - watch:
      - pkg: Install Nessus Package
  {%- endfor %}
{%- endfor %}

Create Sym-link To Log Dir:
  file.symlink:
    - name: '{{ nessus_root }}/var/nessus/logs'
    - target: '{{ real_nessus_log }}'
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - file: Pre-Create Nessus Log Directory

Create Sym-link To Temp Dir:
  file.symlink:
    - name: '{{ nessus_root }}/var/nessus/tmp'
    - target: '{{ real_nessus_tmp }}'
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - file: Pre-Create Nessus Temp Directory

Install Nessus Package:
  pkg.installed:
    - sources:
      - {{ nessus.package }}: {{ nessus.package_url }}
    - require:
      - file: Create Sym-link To Log Dir
      - file: Create Sym-link To Temp Dir
    - skip_verify: True

Pre-Create Nessus Log Directory:
  file.directory:
    - name: '{{ real_nessus_log }}'
    - user: root
    - group: root
    - dir_mode: '0755'
    - recurse:
      - user
      - group
      - mode
    - makedirs: True

Pre-Create Nessus Temp Directory:
  file.directory:
    - name: '{{ real_nessus_tmp }}'
    - user: root
    - group: root
    - dir_mode: '0755'
    - recurse:
      - user
      - group
      - mode
    - makedirs: True

# Ensure that any "leftover" files Nessus may have created get cleaned up by the
# systemd-tmpfiles service (service only runs daily, so the "10min" value may be
# effectively moot
Setup systmed tmpfiles service entry:
  file.managed:
    - name: '/etc/tmpfiles.d/nessus_agent.conf'
    - contents: |
        d {{ real_nessus_tmp }} 0755 root root 10min
    - group: root
    - mode: '0700'
    - require:
      - file: 'Pre-Create Nessus Temp Directory'
    - selinux:
        serange: 's0'
        serole: 'object_r'
        setype: 'etc_t'
        seuser: 'system_u'
    - user: root
