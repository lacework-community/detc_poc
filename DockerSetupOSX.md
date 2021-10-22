# Docker Desktop replacement

Docker Desktop has changed their license and require payment for most use cases.  This document will outline a drop in replacement for Docker Desktop (minus the actual desktop interface).

## minikube

Minikube allows for easily running a Kubernetes cluster locally and will work for normal Docker use cases as well.

Currently there is an issue running with the default (hyperkit) driver.  To get around this issue virtualbox will be the drive or choice.

## Install virtual box

Installing virutalbox will require granting permission and restarting.

    brew install virtualbox

## Start docker with virtual box

Make sure to start minikube passing 'virtualbox' as the driver to use.

    minikube start --vm-driver=virtualbox

## Setup current shell to access Docker

Run the command below and copy/paste the exports into your terminal.

    minikube docker-env

## Configure all shell instances to access Docker

Run this command in your shell:

    echo 'eval $(minikube docker-env)' >> ~/.zshrc

Now when a new shell is launched Docker will be setup automatically.
