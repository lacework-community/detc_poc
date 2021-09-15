#!/bin/bash

cd cli; pip install --editable . > /dev/null; cd ..

if [ "$1" == "bash" ]
then
  bash
elif [ "$1" == "fish" ]
then
  fish
else
  detc "$@"
fi