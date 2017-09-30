#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

oldShortName=sanity
newShortName="$1"
oldFullName=sanity
newFullName="$2"

grep -R $oldShortName

echo "==========================================================================="
find . -type f -print0 | xargs -0 sed -i "s/$oldFullName/$newFullName/g"
find . -type f -print0 | xargs -0 sed -i "s/$oldShortName/$newShortName/g"

#check for errors
if [ $? -ne 0 ]; then
	cd "$backup"
	echo "Failed"
	exit 1
fi

echo "==========================================================================="
grep -R "$newShortName"
grep -R "$newFullName"

echo "==========================================================================="
find . -type d -print0 | xargs -0 rename "s/$oldShortName/$newShortName/g"
find . -type f -print0 | xargs -0 rename "s/$oldShortName/$newShortName/g"

echo "==========================================================================="
find . -name '*~' -exec rm {} \;
rm -rf installer/amd64
rm -rf installer/i386
rm -rf installer/*.deb
rm -rf installer/*.run
rm -rf .bzr

echo "==========================================================================="
bzr init

echo "==========================================================================="
echo "Done"

cd "$backup"
