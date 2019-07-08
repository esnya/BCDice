#!/bin/bash

if [ $BCDICE_ENABLED ]; then
  cd $(dirname $0)/..
  npm install || exit $?
fi
