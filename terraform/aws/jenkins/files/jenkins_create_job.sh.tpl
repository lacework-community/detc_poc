#!/bin/bash

/bin/bash -c \
  "cd server;sh -x ./scripts/setup_client.sh; USERACCOUNT=${ jenkins_admin } PASSWORD=${ jenkins_admin_password } sh -x ./scripts/create_job.sh redis-scanning jobs/redis_scanning.xml"
