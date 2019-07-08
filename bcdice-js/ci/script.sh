#!/bin/bash

if [ $BCDICE_ENABLED ]; then
  cd $(dirname $0)/..
  ./node_modules/.bin/run-s build test example || exit $?
fi
