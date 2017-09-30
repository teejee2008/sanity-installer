#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

sh build-stubs.sh

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"; echo "Failed"; exit 1;
fi

echo ""
echo "=========================================================================="
echo " build-install.sh"
echo "=========================================================================="
echo ""

sudo make install

cd "$backup"
