vim:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-editors/vim
    {% else %}
    - name: vim
    {% endif %}

screen:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: dev-vcs/git
    {% else %}
    - name: screen
    {% endif %}

git:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-admin/sudo
    {% else %}
    - name: git
    {% endif %}

dstat:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: sys-apps/dstat
    {% else %}
    - name: dstat
    {% endif %}

dnsutils:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: net-dns/bind-tools
    {% elif grains['os'] == 'Arch ARM' %}
    - name: bind-tools
    {% else %}
    - name: dnsutils
    {% endif %}

htop:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: sys-process/htop
    {% else %}
    - name: htop
    {% endif %}

whois:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: net-misc/whois
    {% else %}
    - name: whois
    {% endif %}

sudo:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-admin/sudo
    {% else %}
    - name: sudo
    {% endif %}

jq:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-misc/jq
    {% else %}
    - name: jq
    {% endif %}


{% if grains['os'] == 'Ubuntu' %}
install Ubuntu Make:
  pkgrepo.managed:
    - humanname: Ubuntu Make packages
    - name: "deb http://ppa.launchpad.net/ubuntu-desktop/ubuntu-make/ubuntu xenial main"
    - dist: xenial
    - file: /etc/apt/sources.list.d/ubuntu-make.list
    - keyid: A1231595
    - keyserver: keyserver.ubuntu.com
  pkg.installed:
    - name: ubuntu-make

network-manager-openvpn:
  pkg.installed
network-manager-openvpn-gnome:
  pkg.installed

wmctrl:
  pkg.installed

systemd-ui:
  pkg.installed

systemd-container:
  pkg.installed

{% endif %}

bsdtar:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-arch/bsdtar
    {% else %}
    - name: bsdtar
    {% endif %}

torrent cli client:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: net-p2p/ctorrent
    {% else %}
    - name: ctorrent
    {% endif %}
