# https://github.com/shamil/docker-jenkins-auto-slave
FROM openjdk:11-slim-bullseye

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG git_lfs_version=2.13.3

ENV JENKINS_HOME=/var/jenkins_home \
    JENKINS_USER=root

RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg2 \
    && apt-get install -y --no-install-recommends curl dumb-init git libltdl7 openssh-client procps lsb-release software-properties-common gettext-base \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/* \

    # Install git LFS
    && curl -#LSo git-lfs.deb https://packagecloud.io/github/git-lfs/packages/debian/buster/git-lfs_${git_lfs_version}_amd64.deb/download.deb \
    && dpkg -i git-lfs.deb \
    && rm -f git-lfs.deb \

    # Jenkins is run with user `jenkins`, uid = 1000
    # If you bind mount a volume from the host or a data container,
    # ensure you use the same uid
    && groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    
    # Tweak global SSH client configuration
    && sed -i '/^Host \*/a \ \ \ \ ServerAliveInterval 30' /etc/ssh/ssh_config \
    && sed -i '/^Host \*/a \ \ \ \ StrictHostKeyChecking no' /etc/ssh/ssh_config \
    && sed -i '/^Host \*/a \ \ \ \ UserKnownHostsFile /dev/null' /etc/ssh/ssh_config

# install lacework scanner
RUN curl -o install.sh https://raw.githubusercontent.com/lacework/circleci-orb-lacework/master/scripts/install.sh \
    && /bin/bash -x ./install.sh

# install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
      && chmod +x ./kubectl \
      && mv ./kubectl /usr/local/bin

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

COPY jenkins-agent /usr/local/bin/jenkins-agent

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/jenkins-agent"]
