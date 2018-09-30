include:
  - /formulas/salt/install

/etc/salt/master.d/gitfs_pillar.conf:
  file.managed:
    - contents: |
        ext_pillar:
          - git:
            - {{ pillar['gitfs_pillar_configuration']['branch'] }} {{ pillar['gitfs_pillar_configuration']['url'] }}:
              - env: base
      ext_pillar_first: true
      pillar_gitfs_ssl_verify: True          

{% for directive, contents in pillar.get('master-config', {}).items() %}
/etc/salt/master.d/{{ directive}}.conf:
  file.managed:
    - contents_pillar: master-config:{{ directive }}
{% endfor %}

/etc/salt/master:
  file.managed:
    - contents: ''
    - contents_newline: False

salt-master:
  service.running:
    - watch:
      - file: /etc/salt/master
      - file: /etc/salt/master.d/*
