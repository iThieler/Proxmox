#!/bin/bash

if [ -n "${1}" ]; then
  configFILE="$1"
fi

DIR_PATH=$(realpath "$0")

path=$DIR_PATH/$(basename “${BASH_SOURCE:-$0}”)

echo "The absolute path is ${path}"
echo "----------------------------------"
echo "The directory path is ${DIR_PATH}"
echo "----------------------------------"
echo "The configFile is ${configFile}"