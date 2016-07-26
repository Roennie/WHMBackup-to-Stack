#!/bin/sh
##############################################
### whmbackup.sh v0.21
# Script to automatically send off nightly WHM
# backups to TransIP Stack.
# --------------------------------------------
# More details coming soon
##############################################

###
# Set these variables to match your preferences
# and environment
###

# DO NOT EDIT THIS LINE
NOW="$(date +'%Y-%m-%d')"

# GPG
GPGKEY=0 # 0 = use passphrase, 1 = use keyfile
GPGPASS="your-ultra-secure-GPG-passphrase"

# FILES & FOLDERS
WORK_DIR=`pwd`
BACK_DIR="$WORK_DIR/backups"
UNSEC_FILE="$BACK_DIR/unsec_backup_$NOW.gz"
WHM_FOLDER="/backup/$now"
LOGFILE="$WORK_DIR/"backup_log_"$(date +'%Y_%m')".txt

# REMOTE
STACK_USER="your-TransIP-Stack-username"
STACK_PASS="your-TransIP-Stack-password"
STACK_DIR="backups/server"

# DEPENDENCIES
PATH_TAR="/usr/bin/tar"
PATH_GPG="/usr/bin/gpg"
PATH_CAD="/usr/bin/cadaver"

###
# Stop editing here, script start
###
APP_VER="0.21-GIT"

printf "%s" "
################################
###    whmbackup $APP_VER    ###
################################
#        SANITY CHECKS         #
"
# Check whether tar is set
if [ ! -f $PATH_TAR ]; then
	echo "Could not find tar, which is a required dependency"
    exit 1
else
    echo "# TAR: Found!                   #"
fi
# Check whether GPG is set
if [ ! -f $PATH_GPG ]; then
	echo "Could not find gpg, which is a required dependency"
    exit 1
else
    echo "# GPG: Found!                   #"
fi
# Check whether cadaver is set
if [ ! -f $PATH_CAD ]; then
	echo "Could not find cadaver, which is a required dependency"
    exit 1
else
    echo "# Cadaver: Found!               #"
fi

echo "################################"

# Set PID file location
HOMEDIR=`echo ~ 2> /dev/null`
if [ "${HOMEDIR}" = "" ]; then HOMEDIR="/tmp"; PIDFILE="$HOMEDIR/whmbackup.pid"; fi
# Check whether whmbackup.sh is already running
if [ -f "${HOMEDIR}/whmbackup.pid" ]; then
	echo "ERROR: whmbackup seems to be running already, exiting"
	echo "ERROR: whmbackup exited prematurely, PID file already existed" >> "$LOGFILE"
	exit 1

fi

echo "NOTICE: whmbackup commences" 

# Make a small and neat package
$PATH_TAR -zcvf $UNSEC_FILE $WHM_FOLDER

# I can haz GPG encryptz?
$PATH_GPG --yes --batch --passphrase=$GPGPASS -c $BACK_DIR/backup_$NOW.tar.gz

# Transfer the GPG encrypted file to TransIP Stack
$PATH_CAD -t <<EOF
open https://$STACK_USER.stackstorage.com/remote.php/webdav
cd $STACK_DIR
put $BACK_DIR/backup_$NOW.tar.gz.gpg ./backup_$NOW.tar.gz.gpg
quit
EOF

echo "Delete old backups" >> "$logfile"

find $BACK_DIR -name "*.tar.gz.gpg" -exec rm {} \; > /dev/null 2>&1
find $BACK_DIR -mtime +1 -name "*.tar.gz" -exec rm {} \; > /dev/null 2>&1

exit 0;
