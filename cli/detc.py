import click
import validators
import helpers
import os

@click.group()
def cli():
  """Welcome to the DETC deployment tool"""
  pass

@cli.command()
@click.argument("cloud")
@click.argument("action")
def traffic_http(cloud, action):
  """Traffic HTTP: provision a compute instance and install HTTP traffic driver

     Example command: detc traffic-http aws init

    \b
    CLOUD:
      aws: cloud provider
      azure: cloud provider
      gcp: cloud provider
    ACTION
      init: Initializes terraform modules
      plan: Runs terraform plan for cloud provider
      deploy:  Provision a compute instance and install the http traffic driver
      destroy: Destroy a compute instance
  """

  if "init" == action.lower():
    helpers.traffic_init(cloud)
  if "plan" == action.lower():
    helpers.traffic_plan(cloud)
  elif "deploy" == action.lower():
    helpers.traffic_deploy(cloud)
  elif "destroy" == action.lower():
    helpers.traffic_destroy(cloud)
  else:
    raise Exception("Traffic action '{}' is NOT known.".format(action))

@cli.command()
@click.argument("action")
def lacework(action):
  """Lacework: Deploy Agents Pods

    \b
    ACTION
      deploy-pods: runs 'kubetcl apply'  commands to deploy the lacework pods to an existing K8 cluster
      destroy-pods: runs 'kubetcl delete' commands to remove the lacework pods from an existing K8 cluster
  """

  if "deploy-pods" == action.lower():
    helpers.lacework_deploy_pods()
  elif "destroy-pods" == action.lower():
    helpers.lacework_destroy_pods()
  else:
    raise Exception("Lacework action '{}' is NOT known.".format(action))


@cli.command()
@click.argument("action")
def gcp(action):
  """GCP: Cloud Management

    \b
    ACTION
      authenticate:   runs glcoud commands to authenticate with GCP, require browser interactions
      enable-service: runs glcoud commands to enable services need to deploy a GKE K8 cluster
  """

  if "authenticate" == action.lower():
    helpers.gcp_authenticate()
  elif "enable-service" == action.lower():
    helpers.gcp_enable_services()
  else:
    raise Exception("GCP action '{}' is NOT known.".format(action))

@cli.command()
@click.argument("action")
def azure(action):
  """Azure: Cloud Management

    \b
    ACTION
      authenticate:   runs az commands to authenticate with Azure, require browser interactions
  """

  if "authenticate" == action.lower():
    command = "az login"
    helpers.run_command(command)
  else:
    raise Exception("GCP action '{}' is NOT known.".format(action))

@cli.command()
@click.argument("cluster")
@click.argument("command")
@click.argument("action")
@click.option("--deployment-path", required=False, help="Path to the kubectl deployment yml file")
@click.option("--skip-undeployment", required=False, help="Skip destroying a kubectl deployment")
def k8(cluster, command, action, deployment_path, skip_undeployment):
  """K8: Cluster Management

     \b
     CLUSTER:
        aks, eks, gke

     \b
     COMMANDS:
       terraform
       ACTIONS:
          init:    runs 'terraform init' to download any needs decencies
          plan:    runs 'terraform plan' to create the cluster
          apply:   runs 'terraform apply' to create the cluster
          destroy: runs 'terraform destroy' to remove the cluster
                   note: for the destroy action a deployment-path or skip-undeployment option is required
       kubectl
       ACTIONS:
          configure:    uses the current k8 cluster/cloud CLI to configure kubectl
          apply:        runs 'kubectl apply' to deploy a set of pods/services to the cluster
          get-pods:     runs 'kubectl get pods' to view the deployed pods
          get-services: runs 'kubectl get services' to view the running services
          destroy:      runs 'kubectl destroy' to removes the pods/services from the cluster
  """

  cluster_path = helpers.get_k8_terraform_path(cluster)
  validators.validate_path_exists(cluster_path)

  # click.echo("command: {}".format(command))
  # click.echo("action: {}".format(action))

  if "terraform" == command.lower():
    helpers.terraform(action, cluster_path, deployment_path, skip_undeployment)
  elif "kubectl" == command.lower():
    helpers.kubectl(action, cluster_path, cluster, deployment_path)
  else:
    raise Exception("Command '{}' is not known.".format(command))

