
include:
  - python2
  - python3

sqlite3:
  pkg.installed

/opt/chromedriver:
  file.directory:
    - user: cpr
    - group: adm
    - dir_mode: 2775
    - file_mode: 664

chromedriver archive:
  file.managed:
    - user: cpr
    - group: adm
    - skip_verify: true
    - name: /srv/salt/files/chromedriver_linux64.zip
    - source: https://chromedriver.storage.googleapis.com/2.28/chromedriver_linux64.zip


chromedriver extracted file:
  archive.extracted:
    - name: /opt/chromedriver
    - source: salt://files/chromedriver_linux64.zip
    - use_cmd_unzip: True
    - archive_format: zip
    - user: cpr
    - clean: true
    - enforce_toplevel: False
    - group: cpr

chromedriver archive permissions:
  file.managed:
    - user: cpr
    - group: adm
    - skip_verify: true
    - name: /opt/chromedriver/chromedriver
    - file_mode: 774

{% for item in ['xvfb', 'unzip', 'xserver-xephyr'] %}
{{ item }}:
  pkg.installed
{% endfor %}



{% for item in ['pyvirtualdisplay', 'selenium', 'feedparser', 'lxml', 'rq', 'prometheus-client'] %}
{{ item }}:
  pip.installed:
    - name: {{ item }}
    - bin_env: '/usr/bin/pip3'
    - upgrade: True
    - require:
      - pkg: pip3
{% endfor %}

