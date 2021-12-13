
#!/bin/bash
# Packages
sudo apt-get update &> /dev/null
sudo apt-get install -y wget curl unzip

# Terraform
# https://computingforgeeks.com/how-to-install-terraform-on-linux/
TER_VER=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip
unzip terraform_${TER_VER}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod a+x /usr/local/bin/terraform

# Setup TF
cd /home/adminuser/tf
/usr/local/bin/terraform init

# Setup cron
systemctl enable cron
echo "*/10 * * * * /home/adminuser/tf/azure_run.sh &> /var/tmp/tf.log" | crontab -
crontab -l
