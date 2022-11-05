#!/bin/bash

if [ -z "${1}" ]; then
  configFILE="$1"
fi

fileName=$(basename "${BASH_SOURCE:-$0}")
filePATH=$(realpath "$0" | sed -e "s|${fileNAME}||g")

echo "The Filepath is ${filePATH}"
echo "----------------------------------"
echo "The FileName is ${fileName}"
echo "----------------------------------"
echo "The configFile is ${configFile}"
