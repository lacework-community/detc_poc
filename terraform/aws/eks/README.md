# Provision a quick EKS cluster

## Create new IAM User

Log into the AWS Console and find 'IAM' -> 'Users' - > 'Add users'.  Give the user a name and click the 'Programmatic access' checkbox and click on 'Next: Permissions'. Click on 'Attach existing policies directly' and check 'AdministratorAccess' and then click 'Next: Tags' -> 'Next: Review' -> 'Create user'.  Set the 'AWS_ACCESS_KEY_ID' in '/docker-composer' 'Access key ID' and set 'AWS_SECRET_ACCESS_KEY' to the 'Secret access key'.  Set 'TF_VAR_AWS_REGION' to the AWS region you want to use.

## Initialize terraform

   docker-compose run detc k8 eks terraform init

## Provision EKS K8 Cluster

   docker-compose run detc k8 eks terraform apply

## Configure Kubectl to talk to the K8 Cluster

   docker-compose run detc k8 eks kubectl configure

## Destory Kubectl EKS K8 Cluster

   docker-compose run detc k8 eks terraform destroy --skip-undeployment=true
