#!/bin/bash
. $(pwd)/scripts/check_for_auth.sh
. $(pwd)/scripts/check_for_lw_auth.sh

docker run \
  --name jenkins --rm \
  -p 50000:50000 -p 8080:8080 \
  --env JENKINS_ADMIN_ID=$USERNAME \
  --env JENKINS_ADMIN_PASSWORD=$PASSWORD \
  --env LW_ACCESS_ACCOUNT=$LW_ACCESS_ACCOUNT \
  --env LW_ACCESS_TOKEN=$LW_ACCESS_TOKEN \
  jenkins:testing
