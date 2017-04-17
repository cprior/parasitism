python2:
  pkg.installed:
    {% if grains['os'] == 'Ubuntu' %}
    - name: python
    {% endif %}

pip2:
  pkg.installed:
    {% if grains['os'] == 'Ubuntu' %}
    - name: python-pip 
    {% endif %}

virtualenv2:
  pkg.installed:
    {% if grains['os'] == 'Ubuntu' %}
    - name: virtualenv
    {% endif %}

jupyter notebook ipython2:
  pip.installed:
    - name: ipykernel
    - bin_env: '/usr/bin/pip'
#    - upgrade: True
    - require:
      - pkg: pip2

make sure pylint is installed:
  pip.installed:
    - name: pylint
    - bin_env: '/usr/bin/pip'
    - upgrade: True
    - require:
      - pkg: pip2
