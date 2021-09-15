import click
import subprocess
import time
import sys
import helpers
import validators
import os

# Disable track back details
sys.tracebacklimit = 0

def kubectl(action, cluster_path, cluster, deployment_path):
  if "configure" == action.lower():
    configure_kubectl(cluster, cluster_path)
  elif "undeploy" == action.lower() or "destroy" == action.lower():
    configure_kubectl(cluster, cluster_path)
    kubectl_delete(deployment_path)
  elif "deploy" == action.lower() or "apply" == action.lower():
    configure_kubectl(cluster, cluster_path)
    kubectl_apply(deployment_path)
  elif "get-pods" == action.lower():
    configure_kubectl(cluster, cluster_path)
    command = "kubectl get pods"
    click.echo(command)
    helpers.run_command(command)
  elif "get-services" == action.lower():
    configure_kubectl(cluster, cluster_path)
    command = "kubectl get services"
    helpers.run_command(command)
  else:
    raise Exception("kubectl action '{}' is NOT valid!".format(action))

def get_k8_terraform_path(cluster):
  path = "/terraform"
  if 'eks' == cluster.lower():
    path += "/aws/eks"
  elif 'aks' == cluster.lower():
    path += "/azure/aks"
  elif 'gke' == cluster.lower():
    path += "/gcp/gke"
  else:
    raise Exception("Cluster type '{}' is NOT valid!".format(cluster))
  return path

def configure_kubectl(cluster, path):
  command = "cd {}".format(path)

  if "eks" == cluster.lower():
    command += "; aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)"
  elif "aks" == cluster.lower():
    command += "; az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)"
  elif "gke" == cluster.lower():
    command += "; gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw region)"
  else:
    raise Exception("K8 Cluster '{}' is NOT a known.".format(cluster))

  click.echo("Configuring kubectl for '{}' K8 cluster".format(cluster))
  helpers.run_command(command)

def kubectl_delete(deployment_path):
  if not deployment_path:
    raise Exception("Destroying requires providing the deployment path (--deployment-path=/foo/deployment.yml)")

  validators.validate_file_exists(deployment_path)
  command = "kubectl delete -f {}".format(deployment_path)
  helpers.run_command(command)

def kubectl_apply(deployment_path):
  if not deployment_path:
    raise Exception("Destroying requires providing the deployment path (--deployment-path=/foo/deployment.yml)")

  validators.validate_file_exists(deployment_path)
  command = "kubectl apply -f {}".format(deployment_path)
  helpers.run_command(command)

def terraform(action, path, deployment_path, skip_undeployment):
  terrform_action = action

  if "init" == action.lower():
    pass
  elif "destroy" == action.lower():
    if not skip_undeployment:
      print("Attempting to delete pods with Kubectl.  Add '--skip-undeployment=true' to skip this step.")
      helpers.kubectl_delete(deployment_path)
    terrform_action += " -auto-approve"
  elif "plan" == action.lower():
    pass
  elif "apply" == action.lower():
    terrform_action += " -auto-approve"
  else:
    raise Exception("Terraform action '{}' is NOT valid.".format(action))

  terraform_command = "cd {}; terraform {}".format(path, terrform_action)
  # click.echo(terraform_command)
  helpers.run_command(terraform_command)


def lacework_deploy_pods():
  lacework_access_token = os.environ.get('LACEWORK_ACCESS_TOKEN')

  command = "cp -f /deploys/lacework/lacework-cfg-k8s.yaml.example /deploys/lacework/lacework-cfg-k8s.yaml"
  helpers.run_command(command)

  command = "sed -i 's/LACEWORK_ACCESS_TOKEN/{}/' /deploys/lacework/lacework-cfg-k8s.yaml".format(lacework_access_token)
  helpers.run_command(command)

  command = "kubectl create -f /deploys/lacework/lacework-cfg-k8s.yaml"
  helpers.run_command(command)

  command = "kubectl create -f /deploys/lacework/lacework-k8s.yaml"
  helpers.run_command(command)

def lacework_destroy_pods():
  command = "cp -f /deploys/lacework/lacework-cfg-k8s.yaml.example /deploys/lacework/lacework-cfg-k8s.yaml"
  helpers.run_command(command)

  command = "kubectl delete -f /deploys/lacework/lacework-cfg-k8s.yaml"
  helpers.run_command(command)

  command = "kubectl delete -f /deploys/lacework/lacework-k8s.yaml"
  helpers.run_command(command)

def gcp_authenticate():
  command = "gcloud init"
  helpers.run_command(command)
  command = "gcloud auth application-default login"
  helpers.run_command(command)

def gcp_enable_services():
  command = "gcloud services enable compute.googleapis.com"
  helpers.run_command(command)
  command = "gcloud services enable container.googleapis.com"
  helpers.run_command(command)

def run_command(command):
  process = subprocess.Popen(command, shell=True)#, stdout=writer)
  while process.poll() is None:
      time.sleep(0.1)
