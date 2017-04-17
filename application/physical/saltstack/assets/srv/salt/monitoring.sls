# Saltstack statefile to install Prometheus components.
# Works on Ubuntu 16.04.x
# Rather linear, not polished, but works.

Create a group for the prometheus user:
  group.present:
    - name: prometheus
    - system: True
#    - addusers:
#      - prometheus

And a prometheus user:
  user.present:
    - name: prometheus
    - groups:
      - prometheus
      - adm
    - createhome: False
    - shell: /bin/false

{% for item in ['server', 'node_exporter', 'pushgateway', 'alertmanager'] %}
{{ item }} directory:
  file.directory:
    - name: /opt/prometheus/{{ item }}
    - makedirs: True
{% endfor %}


prometheus storage.local.path:
  file.directory:
    - name: /var/lib/prometheus/server/data
    - makedirs: True
    - user: prometheus
    - group: prometheus
    - file_mode: 660
    - dir_mode: 2770
    - recurse:
      - user
      - group

#https://github.com/prometheus/alertmanager/blob/master/cmd/alertmanager/main.go#L79
alertmanager storage.path:
  file.directory:
    - name: /var/lib/prometheus/alertmanager/data
    - makedirs: True
    - user: prometheus
    - group: prometheus
    - file_mode: 660
    - dir_mode: 2770
    - recurse:
      - user
      - group


########## prometheus server ##########

/srv/salt/files/prometheus-1.6.0.linux-amd64.tar.gz:
  file.managed:
    - source: https://github.com/prometheus/prometheus/releases/download/v1.6.0/prometheus-1.6.0.linux-amd64.tar.gz
    - source_hash: c5859329efca767a3a4f7fdb5f97f7bc5a4c85bce9f9fa3aa2a6394e70f399af

prometheus server installation:
  archive.extracted:
    - name: /opt/prometheus/server
    - enforce_toplevel: False
    - options: --strip-components=1
    - source: salt://files/prometheus-1.6.0.linux-amd64.tar.gz
    - skip_verify: true
    - group: adm

systemd prometheus.service unit file:
  file.managed:
    - name: /etc/systemd/system/prometheus.service
    - contents: |
        [Unit]
        Description = The Prometheus monitoring system and time series database.
        
        [Service]
        Type = simple
        User=prometheus
        Restart=on-failure
        ExecStart=/opt/prometheus/server/prometheus -config.file=/opt/prometheus/server/prometheus.yml -storage.local.path=/var/lib/prometheus/server/data
        
        [Install]
        WantedBy = multi-user.target

enable the prometheus service:
  service.running:
    - name: prometheus.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/prometheus.service
    - watch:
      - file: /etc/systemd/system/prometheus.service


######### pushgateway ##########

/srv/salt/files/pushgateway-0.3.1.linux-amd64.tar.gz:
  file.managed:
    - source: https://github.com/prometheus/pushgateway/releases/download/v0.3.1/pushgateway-0.3.1.linux-amd64.tar.gz
    - source_hash: cfa8938d20c0495fcac007ffe24c6327547483e3090a247bb3f72b37a2584185

prometheus pushgateway installation:
  archive.extracted:
    - name: /opt/prometheus/pushgateway
    - enforce_toplevel: False
    - options: --strip-components=1
    - source: salt://files/pushgateway-0.3.1.linux-amd64.tar.gz
    - skip_verify: true
    - group: adm

systemd pushgateway.service unit file:
  file.managed:
    - name: /etc/systemd/system/pushgateway.service
    - contents: |
        [Unit]
        Description = push acceptor for ephemeral and batch jobs
        
        [Service]
        Type = simple
        User=prometheus
        Restart=on-failure
        ExecStart=/opt/prometheus/pushgateway/pushgateway
        
        [Install]
        WantedBy = multi-user.target

enable the pushgateway service:
  service.running:
    - name: pushgateway.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/pushgateway.service
    - watch:
      - file: /etc/systemd/system/pushgateway.service


######### alertmanager ##########

/srv/salt/files/alertmanager-0.5.1.linux-amd64.tar.gz:
  file.managed:
    - source: https://github.com/prometheus/alertmanager/releases/download/v0.5.1/alertmanager-0.5.1.linux-amd64.tar.gz
    - source_hash: 9df9f0eb0061c8ead1b89060b851ea389fbdf6c1adc8513b40f6f4b90f4de932

prometheus alertmanager installation:
  archive.extracted:
    - name: /opt/prometheus/alertmanager
    - enforce_toplevel: False
    - options: --strip-components=1
    - source: salt://files/alertmanager-0.5.1.linux-amd64.tar.gz
    - skip_verify: true
    - group: adm

systemd alertmanager.service unit file:
  file.managed:
    - name: /etc/systemd/system/alertmanager.service
    - contents: |
        [Unit]
        Description = Prometheus Alertmanager
        
        [Service]
        Type = simple
        User=prometheus
        Restart=on-failure
        ExecStart=/opt/prometheus/alertmanager/alertmanager -config.file=/opt/prometheus/alertmanager/alertmanager.yml -storage.path=/var/lib/prometheus/alertmanager/data
        
        [Install]
        WantedBy = multi-user.target

enable the alertmanager service:
  service.running:
    - name: alertmanager.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/alertmanager.service
    - watch:
      - file: /etc/systemd/system/alertmanager.service


######### node_exporter ##########

/srv/salt/files/node_exporter-0.14.0.linux-amd64.tar.gz:
  file.managed:
    - source: https://github.com/prometheus/node_exporter/releases/download/v0.14.0/node_exporter-0.14.0.linux-amd64.tar.gz
    - source_hash: d5980bf5d0dc7214741b65d3771f08e6f8311c86531ae21c6ffec1d643549b2e

prometheus node_exporter installation:
  archive.extracted:
    - name: /opt/prometheus/node_exporter
    - enforce_toplevel: False
    - options: --strip-components=1
    - source: salt://files/node_exporter-0.14.0.linux-amd64.tar.gz
    - skip_verify: true
    - group: adm

node_exporter.service:
  file.managed:
    - name: /etc/systemd/system/node_exporter.service
    - contents: |
        [Unit]
        Description = Exporter for machine metrics  prometheus/node_exporter
        
        [Service]
        Type = simple
        ExecStart=/opt/prometheus/node_exporter/node_exporter
        
        [Install]
        WantedBy = multi-user.target

enable the node_exporter service:
  service.running:
    - name: node_exporter.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/node_exporter.service
    - watch:
      - file: /etc/systemd/system/node_exporter.service



#nohup ./prometheus > prometheus.log 2>&1 &

#https://askubuntu.com/a/825863
## /etc/systemd/system/prometheus.service
#[Unit]
#Description=Prometheus Server
#Documentation=https://prometheus.io/docs/introduction/overview/
#After=network-online.target
#
#[Service]
#User=prometheus
#Restart=on-failure
#ExecStart=/usr/local/bin/prometheus-1.1.2.linux-amd64/prometheus \
#                                -config.file=/etc/prometheus/prometheus.yml \
#                                -storage.local.path=/var/lib/prometheus/data
#
#[Install]
#WantedBy=multi-user.target

