#!/bin/bash
exec > /var/tmp/tf.log
exec 2>&1

cd /home/adminuser/tf
export PATH=$PATH:/usr/local/bin

%{ for a in apps ~}
# ${a["app_name"]}
export TF_VAR_client_id="${a["client_id"]}"
export TF_VAR_client_secret="${a["client_secret"]}"
export TF_VAR_tenant_id="${a["tenant_id"]}"
export TF_VAR_subscription="${a["sub_id"]}"

TF_VAR_address_prefix="10.0.1.0/24" terraform apply -auto-approve
TF_VAR_address_prefix="10.0.2.0/24" terraform apply -auto-approve
TF_VAR_address_prefix="10.0.2.0/24" terraform destroy -auto-approve

unset TF_VAR_subscription TF_VAR_client_secret TF_VAR_client_id TF_VAR_tenant_id

%{ endfor ~}
