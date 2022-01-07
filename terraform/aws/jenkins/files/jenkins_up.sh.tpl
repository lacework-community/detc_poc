DOCKERHUB_ACCESS_TOKEN=${dockerhub_access_token} \
DOCKERHUB_ACCESS_USER=${dockerhub_access_user} \
JENKINS_URL="http://server:8080" \
JENKINS_ADMIN_ID=${jenkins_admin} \
JENKINS_ADMIN_PASSWORD=${jenkins_admin_password} \
LW_ACCESS_ACCOUNT=${lw_access_account} \
LW_ACCESS_TOKEN=${lw_access_token} \
JENKINS_AUTH="${jenkins_admin}:${jenkins_admin_password}" \
K8S_CLUSTER_NAME='${k8s_cluster_name}' \
K8S_CONTEXT_NAME='${k8s_context_name}' \
K8S_SERVER_URL='${k8s_server_url}' \
K8S_BUILD_ROBOT_TOKEN="${k8s_build_robot_token}" \
SERVER="${server}" \
sudo -E docker-compose up -d ${instance}
