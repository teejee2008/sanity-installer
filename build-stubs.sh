#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

app_name=$(cat app_name)

# build debs
sh build-deb.sh

# make stub folder
mkdir -pv ./src/share/${app_name}/files

for arch in i386 amd64
do

echo ""
echo "=========================================================================="
echo " build-stubs.sh : $arch"
echo "=========================================================================="
echo ""

# extract deb
dpkg-deb -xv ./installer/${arch}/${app_name}*.deb ./installer/${arch}/extracted

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"; echo "Failed"; exit 1;
fi

echo "-------------------------------------------------------------------------"

# copy stubs
cp -pv --no-preserve=ownership ./installer/${arch}/extracted/usr/bin/sanity ./src/share/${app_name}/files/${app_name}.${arch}
chmod a-x ./src/share/${app_name}/files/${app_name}.${arch}

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"; echo "Failed"; exit 1;
fi

echo "-------------------------------------------------------------------------"

done

cd "$backup"
