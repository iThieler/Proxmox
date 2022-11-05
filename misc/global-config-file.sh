#!/bin/bash

configFILE=$1

fileName=$(basename "${BASH_SOURCE:-$0}")
filePATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

echo "The Filepath is ${filePATH}"
echo "----------------------------------"
echo "The FileName is ${fileName}"
echo "----------------------------------"
echo "The configFile is ${configFile}"
