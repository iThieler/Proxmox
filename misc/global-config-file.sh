#!/bin/bash

if [ -n "$1" ]; then
  configFile="$1"
fi
fileName=$(basename "${BASH_SOURCE:-$0}")
filePATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

echo "source ${filePATH}/functions-basic.sh"
echo "source ${filePATH}/functions-whiptail.sh"
echo ""
echo -e "source $(dirname \"$0\")/A.sh"
echo ""
echo "source ${0##*/}/A.sh"
echo ""
echo ""
echo ""

echo "The Filepath is ${filePATH}"
echo "----------------------------------"
echo "The FileName is ${fileName}"
echo "----------------------------------"
echo "The configFile is ${configFile}"
