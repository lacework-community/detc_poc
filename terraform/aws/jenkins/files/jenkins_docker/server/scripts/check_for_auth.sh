#!/bin/bash

if [ -z $USERACCOUNT ]; then
  echo "must set USERACCOUNT"
  exit 1
fi

if [ -z $PASSWORD ]; then
  echo "must set PASSWORD"
  exit 1
fi
