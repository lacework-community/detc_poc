# Provision a AKS K8 Cluster in Azure

## Create new Azure App Registrations

Open the Azure Portal in a web browser and search for 'app registration' and click on 'New Registration' and given the new app registration a name.  Set the field 'TF_VAR_AZURE_APP_ID' in the './docker-compose.yml' file to the 'Application (client) ID' value.  Next click into 'Certificates & Secrets' -. '+ new client secret' -> add a description and click the 'Add' button.  Set the 'TF_VAR_AZURE_PASSWORD' in the './docker-composer.yml' to the 'Value' of the newly created secret.

## Authenticate with Azure

   docker-compose run detc azure authenticate

## Initialize terraform

   docker-compose run detc k8 aks terraform init

## Provision AKS K8 Cluster

   docker-compose run detc k8 aks terraform apply

## Configure Kubectl to talk to the K8 Cluster

   docker-compose run detc k8 aks kubectl configure

## Destory Kubectl AKS K8 Cluster

   docker-compose run detc k8 eks terraform destroy --skip-undeployment=true


