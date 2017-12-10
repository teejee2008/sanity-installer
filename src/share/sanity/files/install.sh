#!/bin/bash

CD_PUSH() {
	cd_backup=`pwd`
}

CD_POP() {
	if [ ! -z "${cd_backup}" ]; then
		cd "${cd_backup}"
	fi
}

BACKUP_IFS(){
	IFS_backup="${IFS}"
}

SET_IFS_NEWLINE(){
	IFS=$'\n'
}

RESET_IFS() {
	if [ ! -z "${IFS_backup}" ]; then
		IFS="${IFS_backup}"
	fi
}

EXIT(){
	RESET_IFS
	CD_POP
	exit $1
}

WAIT_FOR_INPUT() {
	echo ""
	echo "Press any key to exit..."
	read dummy
}

GET_SCRIPT_PATH(){
	SCRIPTPATH="$(cd "$(dirname "$0")" && pwd)"
	SCRIPTNAME=`basename $0`
}

RUN_AS_ADMIN() {
	if [ ! `id -u` -eq 0 ]; then
		GET_SCRIPT_PATH
		if command -v sudo >/dev/null 2>&1; then
			sudo "${SCRIPTPATH}/${SCRIPTNAME}"
			EXIT $?
		elif command -v su >/dev/null 2>&1; then
			su -c "${SCRIPTPATH}/${SCRIPTNAME}"
			EXIT $?
		else
			echo ""
			MSG_ERROR "** Installer must be run as Admin (using 'sudo' or 'su') **"
			echo ""
			EXIT 1
		fi
	fi
}

CD_PUSH
RUN_AS_ADMIN
BACKUP_IFS
SET_IFS_NEWLINE

if [ -e preinst.sh ]; then
	chmod a+x ./preinst.sh
	./preinst.sh
fi

chmod a+x ./sanity
./sanity

if [ -e postinst.sh ]; then
	chmod a+x ./postinst.sh
	./postinst.sh
fi

EXIT 0
