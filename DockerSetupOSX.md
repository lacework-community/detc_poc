# Docker Desktop replacement

Docker Desktop has changed their license and require payment for most use cases.  This document will outline a drop in replacement for Docker Desktop (minus the actual desktop interface).

## minikube

Minikube allows for easily running a Kubernetes cluster locally and will work for normal Docker use cases as well.

Currently there is an issue running with the default (hyperkit) driver.  To get around this issue virtualbox will be the drive or choice.

## Install docker and docker-compose cli commands

To interact with minikube the docker cli tools will need to be installed

   brew install docker docker-compose kubectl

## Install minikube

   brew install minikube

## Install virtual box

Installing virutalbox using the package provided by Virtualbox is probably the easiest.  Download the OSX version and follow the install process.

https://www.virtualbox.org/wiki/Downloads


## Start docker with virtual box

Make sure to start minikube passing 'virtualbox' as the driver to use.

    minikube start --vm-driver=virtualbox

## Setup current shell to access Docker

Run the command below and copy/paste the exports into your terminal.

    minikube docker-env

## Trouble shooting

If you see this message:

    ❌  Exiting due to IF_VBOX_NOT_VISIBLE: Failed to start host: driver start: Error setting up host only network on machine start: The host-only adapter we just created is not visible. This is a well known VirtualBox bug. You might want to uninstall it and reinstall at least version 5.0.12 that is is supposed to fix this issue

You need to grand permission for VirtualBox to start:

    System Preferences -> Security & Privacy -> Allow -> Then allow the software corporation

## Configure all shell instances to access Docker

Run this command in your shell:

    echo 'eval $(minikube docker-env)' >> ~/.zshrc

Now when a new shell is launched Docker will be setup automatically.
