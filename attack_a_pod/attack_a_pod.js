const {program} = require('commander');
program.version('0.0.1');
const puppeteer = require('puppeteer')
const lib = require('./lib/lib')
const attacks = require('./lib/attacks').default

global.verbose = false

async function run() {
  program
    .option('-u, --url <vote_app_url>', 'url of the vote app')
    .option('-a, --attack <attack_to_run>', 'attacks: ' + Object.keys(attacks).toString())
    .option('-r, --remote <remote_host_ip>', 'attackers remote host ip address')
    .option('-k, --sshkey <path to ssh key>', 'ssh private key to be used')
    .option('-p, --sshpubkey <path to ssh pub key>', 'ssh public key to be used')
    .option('-d, --dirname <directory_name>', 'directory name to create for test attack')
    .option('-v, --verbose', 'verbose output and screenshots')
  program.parse(process.argv);
  const options = program.opts();

  if (options['verbose']) {
    console.log('Verbose mode enabled')
    global.verbose = true
  }

  if (options['sshkey']) {
    options['sshkey'] = options['sshkey'].replace(/\n/gm, "||||")
  }

  let url = lib.get_url(options);
  let attack_type = lib.get_attack_type(options, attacks)

  let attack = attacks[attack_type]
  attack = lib.replace_command_with_parameters(attack, options)

  console.log('Running attack: ' + attack_type)
  console.log('Vote App: ' + url)

  const browser = await puppeteer.launch({args: ['--no-sandbox']});
  const page = await browser.newPage();
  await page.setViewport({width: 1366, height: 850});

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
  } finally {
    browser.close();
  }
}

run();
