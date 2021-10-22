# Attack a pod!

This project uses headless Chrome driven by Puppeteer to run a set of attacks against a deployed Voteapp.

## Supported attacks

### postgres_attack

The Voteapp connects to the postgres database.  Normally the Voteapp only talks to a Redis queue.  With this attack we install postgres in the pod and connect to the database and dump all the records.

### escape_pod_via_cron_aws

The Voteapp uses cron to have the node it is running on install netcat and reach out to a remote hots. Once connected to the remote host xmrig is downloaded and ran on the host for a number of seconds (60 at the moment).

### escape_pod_via_ssh_(aws|azure|gcp)

The Voteapp uses ssh to connect to the node it is running on install netcat and reach out to a remote hots. Once connected to the remote host xmrig is downloaded and ran on the host for a number of seconds (60 at the moment).

## Running the netcat remote host

For the escape pod attack a remote host will need to be setup with netcat installed and port 5555 open to the internet (or at least the hosts that are running the Voteapp).  The netcat remote host will also have to have the ['attack.sh'](attack.sh) script on the host.  When you start one of the 'escape pod' attacks, start the netcat as show below.  Once the attack is complete netcat should quit.

Command to run to listen for connections:

    netcat -nvlp 5555 < ./attack.sh

## Find the Voteapp URL

Using the DETC project to find the URL of the VoteApp.  The Voteapp is the service listening on port 80.

    docker-compose run detc k8 [aks|eks|gke] kubectl get-services

Note: you will need to be with the root directory of this repo to run the command above

## Get help on what commands and attacks can be run

    docker-compose run attack node attack_a_pod.js -h

## Run attack on a pod

    docker-compose run attack node --url URL_OF_VOTE_APP --attack NAME_OF_ATTACK
