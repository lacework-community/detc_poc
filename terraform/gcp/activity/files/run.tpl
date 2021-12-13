#!/bin/bash 
exec > /var/tmp/tf.log
exec 2>&1

export PATH=$PATH:/usr/local/bin
cd /root/tf


%{ for k, v in data ~}
# ${k}
export TF_VAR_project=${project}
export TF_VAR_credentials=/root/tf/gcp_auth_${k}.json

TF_VAR_firewall_port=11111 \
  TF_VAR_role="roles/logging.logWriter" \
  terraform apply -auto-approve

TF_VAR_firewall_port=12111 \
  TF_VAR_role="roles/logging.admin" \
  terraform apply -auto-approve

TF_VAR_firewall_port=12111 \
  TF_VAR_role="roles/logging.admin" \
  terraform destroy -auto-approve

unset TF_VAR_credentials TF_VAR_project

%{ endfor ~}
