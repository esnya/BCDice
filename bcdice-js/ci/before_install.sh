#!/bin/bash

if [ $BCDICE_ENABLED ]; then
  nvm install 12 || exit $?
  nvm use 12 || exit $?
  gem install opal || exit $?
fi
