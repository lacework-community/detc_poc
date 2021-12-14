#!/bin/bash
# install lacework scanner
curl -o install.sh https://raw.githubusercontent.com/lacework/circleci-orb-lacework/master/scripts/install.sh \
    && sudo /bin/bash -x ./install.sh
