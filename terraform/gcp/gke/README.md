# Provision a GKE K8 Cluster in GCP

## Create a Google project

In the GCP website Console search for 'Create a Project'.  Create a new project giving it a meaning full name.  Example: 'gke-demo-test'.  Once the project is created grab the 'Project ID' from the project page.  The project ID should look something like: 'gke-demo-test-123456'.

Update the '/docker-comose.yml' env variable 'TF_VAR_GCP_PROJECT_ID' with the Project ID for your GCP project.

## Authenticate with GCP

If you want to re-run the authentication run this:

   docker-compose run detc gcp authenticate

## Enable to GCP API

   docker-compose run detc gcp enable-service

## Initialize terraform

   docker-compose run detc k8 gke terraform init

## Provision EKS K8 Cluster

   docker-compose run detc k8 gke terraform apply

## Configure Kubectl to talk to the K8 Cluster

   docker-compose run detc k8 gke kubectl configure

## Destory Kubectl EKS K8 Cluster

   docker-compose run detc k8 eks terraform destroy --skip-undeployment=true
