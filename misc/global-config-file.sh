#!/bin/bash

if [ -n "$1" ]; then
  configFile="$1"
  echo "$configFile"
fi

fileName=$(basename "${BASH_SOURCE:-$0}")
filePATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

echo "The Filepath is ${filePATH}"
echo "----------------------------------"
echo "The FileName is ${fileName}"
echo "----------------------------------"
echo "The configFile is ${configFile}"
