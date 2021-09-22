# Welcome to the DETC POC Project

## Intro

The DETC POC project enables deploying a demo application into cloud accounts.  Currently this project can provision a K8 cluster, deploy a small web app onto the cluster, install the Lacework monitoring pods onto the cluster and drive traffic over the web app.  And of course all of the provisioned resources can be destroyed.

High level topics covered:

* Build DETC Docker image locally
* Provision a K8 Cluster
* Deploy the Vote app pods/services with Kubectl
* Deploy the Lacework pods with Kubectl
* Tearing it all down

## Prerequisites

Make sure to have all of these items ready before using this project:

* access to at least one cloud account with admin privileges
   * AWS
   * GCP
   * Azure
* access to a Lacework tenant with admin privileges
* Docker and docker-compose setup on a computer

## Build DETC Docker image locally

Currently the docker image needs to be built locally to run locally.  Simply run this command and enjoy a warm beverage:

   docker-compose build

## Provision a K8 Cluster

Each cloud account/cluster has a README file that covers how to get the cluster provisioned, because each cloud is special.

[AWS EKS](terraform/aws/eks/README.md)

[Azure AKS](terraform/azure/aks/README.md)

[GCP GKE](terraform/gcp/gke/README.md)

note: below you will see some commands have '{{ K8-CLUSTER-ACRONYM }}', replace that with eks/aks/gke for the cluster type you have provisioned

## Deploy the Vote app pods/services with Kubectl

Kubectl needs to be configured properly to communicate with the control plane for the cluster. Please refer to the README linked above to find out how to configure kubectl.

   docker-compose run detc k8 {{ K8-CLUSTER-ACRONYM }} kubectl apply --deployment-path=/deploys/voteapp/vote.yml

## Deploy the Lacework pods with Kubectl

To setup Lacework edit the '/docker-compose.yml' file set 'LACEWORK_ACCESS_TOKEN' to a valid a access token for the Lacework tenant being used.  The access token can be found by opening the Lacework tenant in a browser and going to 'Setting' -> 'Agents'.  There should be a clipboard icon that can be used to copy the access token.

   docker-compose run detc lacework deploy-pods

## Drive traffic over the web app

Before deploying the load generation project use kubectl to get the URLs:

    docker-compose run detc k8 {{ K8-CLUSTER-ACRONYM }} kubectl

Find the two externals URLs.  The pod that is listening on port 5000 will go in the 'RESULT_URLS' field in the 'loadgen.js' file.  The other URL will go in the 'VOTE_URLS' field in the 'loadgen.js' file.

[Deploying the loadgen project](loadgen/README.md)

## Tearing it all down

All the provisioned assets can be destroyed.

First destroy any provisioned assets for the web app, mostly this is any external networking services.

   docker-compose run detc k8 {{ K8-CLUSTER-ACRONYM }} kubectl destroy --deployment-path=/deploys/voteapp/vote.yml

Next destroy the provision cluster.

   docker-compose run detc k8 {{ K8-CLUSTER-ACRONYM }} terraform destroy --skip-undeployment=true