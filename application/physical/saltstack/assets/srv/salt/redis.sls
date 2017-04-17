#https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
Create a group for the redis user:
  group.present:
    - name: redis
    - system: True
    - addusers:
      - redis

And a redis user:
  user.present:
    - name: redis
    - groups:
      - redis
    - createhome: False
    - shell: /bin/false

vm.overcommit_memory:
  sysctl.present:
    - value: 1
    - config: /etc/sysctl.d/redis.conf

#http://stackoverflow.com/a/21715218
install-redis-stable:
  cmd.run:
    - name: |
        cd /tmp
        wget -q -c http://download.redis.io/redis-stable.tar.gz
        tar xzf redis-stable.tar.gz
        cd redis-stable
        make -s
        cp src/redis-server /usr/local/bin/
        cp src/redis-cli /usr/local/bin/
    - cwd: /tmp
    - shell: /bin/bash
    - timeout: 300
    - unless: test -x /usr/local/bin/redis-server

/var/lib/redis:
  file.directory:
    - name: /var/lib/redis
    - user: redis
    - group: redis
#    - file_mode: 660
    - dir_mode: 2770

/var/log/redis:
  file.directory:
    - name: /var/log/redis
    - user: redis
    - group: redis
    - file_mode: 664
    - dir_mode: 2775

/etc/redis:
  file.directory:
    - name: /etc/redis

#https://raw.githubusercontent.com/antirez/redis/3.0/redis.conf
/etc/redis/redis.conf:
  file.managed:
    - name: /etc/redis/redis.conf
    - contents:
      - "daemonize yes"
      - "pidfile /var/run/redis/redis.pid"
      - "logfile /var/log/redis/redis.log"
      - "dir /var/lib/redis"

/usr/lib/systemd/system:
  file.directory

/etc/systemd/system/redis.service:
  file.managed:
    - name:  /etc/systemd/system/redis.service
    - contents: |
        [Unit]
        Description=Redis Server
        After=network.target
        
        [Service]
        Type=forking
        User=redis
        Group=redis
        PermissionsStartOnly=true
        ExecStartPre=/bin/bash -c '/bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled'
        ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
        ExecReload=/bin/kill -USR2 $MAINPID
        ExecStop=/usr/local/bin/redis-cli shutdown
        Restart=always
        #
        [Install]
        WantedBy=multi-user.target

redis.service:
  service.running:
    - name: redis.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/redis.service
    - watch:
      - file: /etc/systemd/system/redis.service



RedisDesktopManager_repo: 
  git.latest: 
    - name: https://github.com/uglide/RedisDesktopManager.git
    - target: /tmp/RedisDesktopManager
    - rev: 0.9.0-alpha3
    - submodules: True


opt-qt571-xenial:
  pkgrepo.managed:
    - humanname: Qt 5.7.1 for /opt Xenial
    - name: deb http://ppa.launchpad.net/beineri/opt-qt571-xenial/ubuntu xenial main
    - dist: xenial
    - file: /etc/apt/sources.list.d/opt-qt571-xenial.list
    - keyid: E9977759
    - keyserver: keyserver.ubuntu.com
  pkg.installed:
    - pkgs:
        - qt57-meta-full
    - require:
      - pkgrepo: opt-qt571-xenial


opt-qt562-xenial:
  pkgrepo.managed:
    - humanname: Qt 5.6.2 for /opt Xenial
    - name: deb http://ppa.launchpad.net/beineri/opt-qt562-xenial/ubuntu xenial main
    - dist: xenial
    - file: /etc/apt/sources.list.d/opt-qt562-xenial.list
    - keyid: E9977759
    - keyserver: keyserver.ubuntu.com
  pkg.installed:
    - pkgs:
        - qt56-meta-full
    - require:
      - pkgrepo: opt-qt562-xenial


#install-RedisDesktopManager:
#  cmd.run:
#    - name: |
#        cd /tmp/RedisDesktopManager/src
#        ./configure
#        source /opt/qt56/bin/qt56-env.sh && qmake && make && sudo make install
#        cd /usr/share/redis-desktop-manager/bin
#        sudo mv qt.conf qt.backup
#        cd /tmp
#    - output_loglevel: quiet
#    - cwd: /tmp/RedisDesktopManager
#    - shell: /bin/bash
#    - timeout: 300
#    - unless: test -x /usr/local/lib/python3.5/dist-packages/cv2.cpython-35m-x86_64-linux-gnu.so
