#!/bin/bash
# Start jenkins
cd jenkins_docker
bash -x ./jenkins_up.sh

sleep 60 
while ! curl -s localhost:8080; do   
  sleep 1
done

bash -x ./jenkins_create_job.sh
