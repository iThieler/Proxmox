#!/bin/bash

if [ -n "$1" ]; then
  configFile="$1"
fi

source "$(dirname "${BASH_SOURCE[0]}")/functions-basic.sh"
#source "$(dirname "${BASH_SOURCE[0]}")/functions-whiptail.sh"

pwd

<<com
fileName=$(basename "${BASH_SOURCE:-$0}")
filePATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

source "$(dirname "$0")/functions-basic.sh"
source "$(dirname "$0")/functions-whiptail.sh"

echo "The Filepath is ${filePATH}"
echo "----------------------------------"
echo "The FileName is ${fileName}"
echo "----------------------------------"
echo "The configFile is ${configFile}"
com
