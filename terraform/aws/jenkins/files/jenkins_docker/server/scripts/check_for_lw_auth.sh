#!/bin/bash

if [ -z $LW_ACCESS_ACCOUNT ]; then
  echo "must set LW_ACCESS_ACCOUNT"
  exit 1
fi

if [ -z $LW_ACCESS_TOKEN ]; then
  echo "must set LW_ACCESS_TOKEN"
  exit 1
fi
