FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive

run apt-get update \
    && apt-get install -y \
      gnupg \
      software-properties-common \
      curl \
      fish \
      vim \     
      tmux \
      python3 \
      python3-pip \
      python3.8-venv \
      wget \
      ca-certificates \
      apt-transport-https \
      lsb-release\
      git \
      ack

 # terraform
 RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
     && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
     && apt-get update \
     && apt-get install terraform

# heroku
RUN curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

# kubectl
RUN wget -O /bin/kubectl https://dl.k8s.io/release/$(wget -O-  -q https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x /bin/kubectl

# aws cli
RUN pip3 install --upgrade pip
RUN pip3 install awscli

# azure cli
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc \
    && gpg --dearmor \
    && tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
    && AZ_REPO=$(lsb_release -cs); echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" \
    && tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update \
    && apt-get install -y azure-cli

# gcp cli
RUN curl -sSL https://sdk.cloud.google.com | bash
RUN mv /root/google-cloud-sdk /usr/local
ENV PATH $PATH:/usr/local/google-cloud-sdk/bin

ENTRYPOINT ["bash","./detc.sh"]