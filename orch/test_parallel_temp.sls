{% set type = pillar['type'] %}
{% set identifier = salt.cmd.shell("uuidgen") %}

prepare_vm_{{ type }}-{{ identifier }}:
  salt.state:
    - tgt: controller*
    - sls:
      - orch/states/virtual_prep
    - pillar:
        identifier: {{ identifier }}
        type: {{ type }}
    - concurrent: true
