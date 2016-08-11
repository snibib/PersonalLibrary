#!/usr/bin/env bash

echo -en "033]0;Start Server\a"
clear

THIS_DIR=$(dirname "$0")
pushd "$THIS_DIR"
source build.sh
popd

echo "Process terminated.Press <enter> to close the window"
read

