import click
import subprocess
import sys
import os
import json
import base64
import time
import validators

from typing import Literal, Dict, Tuple, List
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
    run_command(command)
  elif "get-services" == action.lower():
    configure_kubectl(cluster, cluster_path)
    command = "kubectl get services"
    run_command(command)
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
  run_command(command)

def kubectl_delete(deployment_path):
  if not deployment_path:
    raise Exception("Destroying requires providing the deployment path (--deployment-path=/foo/deployment.yml)")

  validators.validate_file_exists(deployment_path)
  command = "kubectl delete -f {}".format(deployment_path)
  run_command(command)

def kubectl_apply(deployment_path):
  if not deployment_path:
    raise Exception("Destroying requires providing the deployment path (--deployment-path=/foo/deployment.yml)")

  validators.validate_file_exists(deployment_path)
  command = "kubectl apply -f {}".format(deployment_path)
  run_command(command)

def terraform(action, path, deployment_path, skip_undeployment, env_variables={}, retry=False, retry_codes: List[int]=[1]):
  terrform_action = action

  if "init" == action.lower():
    pass
  elif "destroy" == action.lower():
    if not skip_undeployment:
      print("Attempting to delete pods with Kubectl.  Add '--skip-undeployment=true' to skip this step.")
      kubectl_delete(deployment_path)
    terrform_action += " -auto-approve"
  elif "plan" == action.lower():
    pass
  elif "apply" == action.lower():
    terrform_action += " -auto-approve"
  else:
    raise Exception("Terraform action '{}' is NOT valid.".format(action))

  terraform_command = "cd {}; terraform {}".format(path, terrform_action)

  for key, value in env_variables.items():
    terraform_command = "export TF_VAR_{}='{}'; {}".format(key, value, terraform_command)

  if retry:
    run_retryable_command(terraform_command, retry_codes, sleep_before_retry=30, times=6)
  else:
    run_command(terraform_command)

def get_build_robot_token_from_kubectl() -> str:
    command = "kubectl get secret build-robot-secret -o=jsonpath='{.data.token}'"
    out, _ = run_command(command, False)
    if(not out):
      raise Exception("Can't connect to kubectl for '{}'".format("aws"))
    return base64.b64decode(out).decode('ascii')

def get_service_url_from_kubectl(service_name, cloud):
  command = "kubectl get service -o=json --field-selector metadata.name={}".format(service_name)
  out, _ = run_command(command, False)
  if(not out):
    raise Exception("Can't connect to kubectl for '{}'".format(cloud))

  service = json.loads(out)
  try:
    ip = port = None
    if(cloud == "aws"):
      ip = service["items"][0]['status']['loadBalancer']['ingress'][0]['hostname']

    if(cloud == "gcp" or cloud == "azure"):
      ip = service["items"][0]['status']['loadBalancer']['ingress'][0]['ip']

    port = service["items"][0]['spec']['ports'][0]['port']
    if(ip and port):
      return "http://{}:{}".format(ip, port)
  except IndexError:
    raise Exception("Not able to get IP address for '{}', are any containers deployed?".format(service_name)) from None
  except KeyError:
    raise Exception("Not able to get IP address for '{}', IP address might not be ready quite yet?".format(service_name)) from None

  raise Exception("Can't get ip address from cloud '{}'".format(cloud))

def get_terraform_path(project, cloud):
    """Derive appropriate terraform code path based on inputs"""
    if not cloud or cloud not in ['aws', 'azure', 'gcp'] or not project or project not in ['traffic', 'activity', 'jenkins']:
        raise Exception("Cloud provider '{}' or project '{}' is NOT valid!".format(cloud, project))

    return '/terraform/{}/{}'.format(cloud, project)

def run_terraform(action: Literal["init", "plan", "destroy", "apply"],
                  project: Literal["traffic", "activity", "jenkins"],
                  cloud: Literal["aws", "azure", "gcp"],
                  deployment_path: str = "",
                  env_vars: Dict = {},
                  skip_undeployment: bool = True,
                  retry: bool = False,
                  retry_codes: List[int] = [1]) -> None:
    """This function is used to launch terraform, supplying the appropriate project for where the source is and the
    appropriate actions to take"""
    terraform(action, get_terraform_path(project, cloud), deployment_path, skip_undeployment, env_vars, retry, retry_codes)

def jenkins_tf(cloud,
               jenkins_admin_pass,
               dockerhub_access_token,
               lw_access_account,
               lw_access_token,
               lw_install_script,
               action: Literal["init", "plan", "apply", "destroy"]):
    build_secret = ""
    if action != "init":
      build_secret = get_build_robot_token_from_kubectl()

    retry = False
    if action == "apply":
        retry = True
    run_terraform(action, "jenkins", cloud, retry=retry, env_vars={
        'k8s_build_robot_token': build_secret,
        'jenkins_admin': "admin",
        'dockerhub_access_user': "ipcrm",
        'jenkins_admin_password': jenkins_admin_pass,
        'dockerhub_access_token': dockerhub_access_token,
        'lw_access_account': lw_access_account,
        'lw_access_token': lw_access_token,
        'lacework_install_script': lw_install_script,
    })

def activity_tf(cloud, action: Literal["init", "plan", "apply", "destroy"]):
    retry = False
    if action == "apply":
        retry = True
    run_terraform(action, "activity", cloud, retry=retry)

def traffic_init(cloud):
  terrform_path = get_terraform_path('traffic', cloud)
  terraform("init", terrform_path, "", True)

def traffic_plan(cloud):
  vote_url = get_service_url_from_kubectl("vote", cloud)
  result_url = get_service_url_from_kubectl("result", cloud)
  env_variables = { "VOTE_URL": vote_url, "RESULT_URL": result_url }

  terrform_path = get_terraform_path('traffic', cloud)
  terraform("plan", terrform_path, "", True, env_variables)

def traffic_deploy(cloud):
  vote_url = get_service_url_from_kubectl("vote", cloud)
  result_url = get_service_url_from_kubectl("result", cloud)
  env_variables = { "VOTE_URL": vote_url, "RESULT_URL": result_url }

  terrform_path = get_terraform_path('traffic', cloud)
  terraform("apply", terrform_path, "", True, env_variables)

def traffic_destroy(cloud):
  env_variables = { "VOTE_URL": "","RESULT_URL": ""}
  terrform_path = get_terraform_path('traffic', cloud)
  terraform("destroy", terrform_path, "", True, env_variables)


def lacework_deploy_pods():
  lacework_access_token = os.environ.get('LACEWORK_ACCESS_TOKEN')

  command = "cp -f /deploys/lacework/lacework-cfg-k8s.yaml.example /deploys/lacework/lacework-cfg-k8s.yaml"
  run_command(command)

  command = "sed -i 's/LACEWORK_ACCESS_TOKEN/{}/' /deploys/lacework/lacework-cfg-k8s.yaml".format(lacework_access_token)
  run_command(command)

  command = "kubectl create -f /deploys/lacework/lacework-cfg-k8s.yaml"
  run_command(command)

  command = "kubectl create -f /deploys/lacework/lacework-k8s.yaml"
  run_command(command)

def lacework_destroy_pods():
  command = "cp -f /deploys/lacework/lacework-cfg-k8s.yaml.example /deploys/lacework/lacework-cfg-k8s.yaml"
  run_command(command)

  command = "kubectl delete -f /deploys/lacework/lacework-cfg-k8s.yaml"
  run_command(command)

  command = "kubectl delete -f /deploys/lacework/lacework-k8s.yaml"
  run_command(command)

def gcp_authenticate():
  command = "gcloud init"
  run_command(command)
  command = "gcloud auth application-default login"
  run_command(command)

def gcp_enable_services():
  command = "gcloud services enable compute.googleapis.com"
  run_command(command)
  command = "gcloud services enable container.googleapis.com"
  run_command(command)

def run_retryable_command(
        command: str,
        retry_code: List[int],
        success_code: int=0,
        times: int=2,
        print_output: bool=True,
        sleep_before_retry: int=0):
    """Use this function to run a command that's retryable on failure

    command: string of the command to execute
    retry_code: command will only be re-run if the exit code is in the retry_code list
    success_code: what return code should be considered success for this command
    times: how many retries should be attempted
    print_output: should the command output be printed while running
    sleep_before_retry: seconds to wait before trying the command again
    """
    executed = 0
    failed = True
    retryable = False
    failed_retry_code = None

    while executed < times and failed:
        if executed > 0:
            if sleep_before_retry > 0:
               print(f"warning => '{command}' did not complete successfully, " + \
                     f'sleeping {sleep_before_retry} seconds and then trying again [{executed} of {times} attempts]')
               time.sleep(sleep_before_retry)
            else:
               print(f"warning => '{command}' did not complete successfully, re-running [{executed} of {times} attempts]")

        _, ret_code = run_command(command, print_output)
        if ret_code == success_code:
            failed = False
            break

        executed += 1
        if ret_code in retry_code:
            retryable = True
        else:
            retryable = False
            failed_retry_code = ret_code
            break


    if failed and not retryable:
        print(f"error => {command} failed to run successfully and could not be retried (unexpected exit code {failed_retry_code})")
    elif failed:
        print(f"error => {command} failed to run after {times} attempts")

def run_command(command, print_output=True) -> Tuple[str, int]:
  process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, encoding='utf-8')
  output = ""
  while True:
    if process.poll() is not None:
      break
    data = process.stdout.readline()
    output += data
    if print_output == True:
      print(data, end="")

  return output, process.returncode
