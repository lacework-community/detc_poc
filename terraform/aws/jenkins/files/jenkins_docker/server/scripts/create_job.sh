#!/bin/bash
. $(pwd)/scripts/check_for_auth.sh

if [ -z $1 ]; then
  echo "must pass job file"
  exit 1
fi

CLIENT_PATH=$(pwd)/jars/jenkins-cli.jar
java -jar $CLIENT_PATH -auth $USERACCOUNT:$PASSWORD  -http -s http://localhost:8080 create-job $1 < $2
