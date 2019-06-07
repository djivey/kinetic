include:
  - /formulas/cache/install
  - formulas/common/base
  - formulas/common/networking

/etc/apt-cacher-ng/acng.conf:
  file.managed:
    - source: salt://formulas/cache/files/acng.conf

apt-cacher-ng_service:
  service.running:
    - name: apt-cacher-ng
    - watch:
      - file: /etc/apt-cacher-ng/acng.conf

{% for os, args in pillar.get('images', {}).items() %}
  {% if args['controller'] == true %}
/var/www/html/images/{{ args['name'] }}:
  file.managed:
    - source: {{ args['remote_url'] }}
    - source_hash: {{ args['remote_hash'] }}
    - makedirs: True
  {% endif %}
{% endfor %}

sha512sum * > checksums:
  cmd.run:
    - cwd: /var/www/html/images
    - onchanges: 
      - file: /var/www/html/images/*

mine.update:
  module.run:
    - network.interfaces: []
  event.send:
    - name: cache/mine/address/update
    - data: "Cache mine has been updated."
