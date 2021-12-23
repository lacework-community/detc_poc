#!/bin/bash -e
# https://github.com/shamil/docker-jenkins-auto-slave

DOWNLOAD_DIR=/usr/share/jenkins
DOCKER_GROUP=docker
DOCKER_SOCKET=/var/run/docker.sock
JENKINS_HOME=/var/jenkins_home
JENKINS_USER=root
JENKINS_AGENT_LABEL='docker'
JENKINS_AGENT_MODE=NORMAL
JENKINS_AGENT_NAME=$HOSTNAME
JENKINS_AGENT_NUM_EXECUTORS=1
JENKINS_AGENT_REMOTE_FS="$JENKINS_HOME"
export JENKINS_URL=${jenkins_url}
export JENKINS_AUTH=${jenkins_auth}

download_agent_jar() {
    curl -Ssfo "$DOWNLOAD_DIR/agent.jar" $JENKINS_URL/jnlpJars/agent.jar
}

download_cli_jar() {
    curl -Ssfo "$DOWNLOAD_DIR/cli.jar" $JENKINS_URL/jnlpJars/jenkins-cli.jar
}

# a wrapper for jenkins_cli utility
jenkins_cli() {
    java -jar "$DOWNLOAD_DIR/cli.jar" -auth "$JENKINS_AUTH" "$@"
}

# not really used, we use 'jnlpCredentials' instead
# kept for reference
get_node_secret() {
    jenkins_cli groovy = \
        <<< "println jenkins.model.Jenkins.instance.nodesObject.getNode('$JENKINS_AGENT_NAME')?.computer?.jnlpMac"
}

which curl &>/dev/null || {
    echo "please install curl"
    exit 1
}

[ -z "$JENKINS_URL" -o -z "$JENKINS_AUTH" ] && {
    echo "please set both JENKINS_URL and JENKINS_AUTH env. variables"
    echo "example:"
    echo "  JENKINS_AUTH=user:token"
    echo "  JENKINS_URL=http://localhost:8080"
    exit 1
}

# download required jars
mkdir -p "$DOWNLOAD_DIR"
download_agent_jar
download_cli_jar

# if docker socket provided, then
# allow docker cli to run as jenkins user
[ -S "$DOCKER_SOCKET" ] && {
    DOCKER_GID=$(stat -c '%g' "$DOCKER_SOCKET")
    groupadd -for -g $DOCKER_GID $DOCKER_GROUP
    usermod -aG $DOCKER_GROUP $JENKINS_USER
}

# make sure to delete node on exit
trap 'exit' SIGINT SIGTERM
trap 'jenkins_cli delete-node "$JENKINS_AGENT_NAME" || true' EXIT

# create node, unless it's already exists
jenkins_cli get-node "$JENKINS_AGENT_NAME" &>/dev/null || {
    CONFIG="<slave><label>$JENKINS_AGENT_LABEL</label><launcher class='hudson.slaves.JNLPLauncher' /><mode>$JENKINS_AGENT_MODE</mode><numExecutors>$JENKINS_AGENT_NUM_EXECUTORS</numExecutors><remoteFS>$JENKINS_AGENT_REMOTE_FS</remoteFS></slave>"
    jenkins_cli create-node "$JENKINS_AGENT_NAME" <<< "$CONFIG"
}

# run agent
/bin/bash -c \
    "java $JAVA_OPTS -jar '$DOWNLOAD_DIR/agent.jar' -jnlpCredentials '$JENKINS_AUTH' -jnlpUrl '$JENKINS_URL/computer/$JENKINS_AGENT_NAME/jenkins-agent.jnlp'"

# exit gracefully
exit 0
