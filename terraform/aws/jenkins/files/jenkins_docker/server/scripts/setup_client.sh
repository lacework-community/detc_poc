#!/bin/bash
CLIENT_PATH=$(pwd)/jars/jenkins-cli.jar
curl http://localhost:8080/jnlpJars/jenkins-cli.jar --output $CLIENT_PATH
