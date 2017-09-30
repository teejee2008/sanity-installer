#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

app_name=$(cat app_name)

echo ""
echo "=========================================================================="
echo " build-source.sh"
echo "=========================================================================="
echo ""

echo "app_name: $app_name"
echo "--------------------------------------------------------------------------"

# remove stubs before build
rm -vf ./src/share/${app_name}/files/${app_name}.amd64
rm -vf ./src/share/${app_name}/files/${app_name}.i386
ls -l ./src/share/${app_name}/files

echo "-------------------------------------------------------------------------"

# commit to bzr repo
bzr add *
bzr commit -m "updated"

#skip errors as commit may fail if no changes

echo "-------------------------------------------------------------------------"

# clean build dir
rm -rf ../builds

# build source
bzr builddeb --source --native --build-dir ../builds/temp --result-dir ../builds

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"; echo "Failed"; exit 1;
fi

echo "-------------------------------------------------------------------------"

# list files
ls -l ../builds

echo "-------------------------------------------------------------------------"

cd "$backup"
