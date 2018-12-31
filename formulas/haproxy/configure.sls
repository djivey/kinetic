include:
  - /formulas/haproxy/install
  - formulas/common/base
  - formulas/common/networking

{% for domain in pillar['haproxy']['tls_domains'] %}

haproxy_{{ domain }}_service_dead:
  service.dead:
    - name: haproxy
    - prereq:
      - letsencrypt certonly -d {{ domain }} --non-interactive --standalone --agree-tos --email {{ pillar['haproxy']['tls_email'] }}

letsencrypt certonly -d {{ domain }} --non-interactive --standalone --agree-tos --email {{ pillar['haproxy']['tls_email'] }}:
  cmd.run:
    - creates:
      - /etc/letsencrypt/live/{{ domain }}/fullchain.pem
      - /etc/letsencrypt/live/{{ domain }}/privkey.pem

cat /etc/letsencrypt/live/{{ domain }}/fullchain.pem /etc/letsencrypt/live/{{ domain }}/privkey.pem > /etc/letsencrypt/live/{{ domain }}/master.pem:
  cmd.run:
    - creates:
      - /etc/letsencrypt/live/{{ domain }}/master.pem

haproxy_{{ domain }}_service_running:
  service.running:
    - name: haproxy

systemctl stop haproxy.service && letsencrypt renew --non-interactive --standalone --agree-tos && cat /etc/letsencrypt/live/{{ domain }}/fullchain.pem /etc/letsencrypt/live/{{ domain }}/privkey.pem > /etc/letsencrypt/live/{{ domain }}/master.pem && systemctl start haproxy.service:
  cron.present:
    - dayweek: 0
    - minute: {{ loop.index0 }}
    - hour: 4

{% endfor %}

/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://formulas/haproxy/files/haproxy.cfg
    - template: jinja
    - defaults:
         hostname: {{ grains['id'] }}
         syslog: {{ pillar['syslog_url'] }}
         public_ip_address: {{ grains['ipv4'][1] }}
         management_ip_address: {{ grains['ipv4'][0] }}
         dashboard_domain: {{ pillar['haproxy']['dashboard_domain'] }}
         console_domain:  {{ pillar['haproxy']['console_domain'] }}
         keystone_hosts: |
           {%- for host, address in salt['mine.get']('type:keystone', 'network.ip_addrs', tgt_type='grain') | dictsort() %}
           server {{ host }} {{ address[0] }}:5000 check inter 2000 rise 2 fall 5
           {% endfor %}
         glance_api_hosts: |
           {%- for host, address in salt['mine.get']('type:glance', 'network.ip_addrs', tgt_type='grain') | dictsort() %}
           server {{ host }} {{ address[0] }}:9292 check inter 2000 rise 2 fall 5
           {% endfor %}
         glance_registry_hosts: |
           {%- for host, address in salt['mine.get']('type:glance', 'network.ip_addrs', tgt_type='grain') | dictsort() %}
           server {{ host }} {{ address[0] }}:9191 check inter 2000 rise 2 fall 5
           {% endfor %}
         dashboard_hosts: |
           server horizon 10.10.123.123:80 check inter 2000 rise 2 fall 5
         nova_spiceproxy_hosts: |
           server nova 10.10.123.123:6082 check inter 2000 rise 2 fall 5

haproxy_cfg_watch:
  service.running:
    - name: haproxy
    - watch:
      - file: /etc/haproxy/haproxy.cfg
