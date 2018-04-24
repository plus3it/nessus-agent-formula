#
# This salt state installs McAfee Agent dependencies, configures iptables, and
# runs a downloaded copy of ePO server's exported install.sh. The `install.sh`
# file is a pre-configured, self-installing SHell ARchive. The SHAR installs
# the MFEcma and MFErt RPMs, service configuration (XML) files and SSL keys
# necessary to secure communications between the local McAfee agent software
# and the ePO server.
#
#################################################################
{%- from tpldir ~ '/map.jinja' import mcafee with context %}


Install Nessus Agent:
  cmd.run:
    - name: 'sh /root/install.sh -i'
    - cwd: '/root'
    - require:
      - file: Stage McAfee Install Archive
    - unless:
{%- for rpm in mcafee.rpms %}
      - 'rpm --quiet -q {{ rpm }}'
{%- endfor %}
{%- for key_file in mcafee.key_files %}
      - 'test -s {{ mcafee.keystore_directory }}/{{ key_file }}'
{%- endfor %}
