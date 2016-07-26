#!/bin/sh
##############################################
### WHMBackup-to-Stack v0.22-GIT
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

# APPLICATION
APP_NAME="WHMBackup-to-Stack"
APP_VER="0.22-GIT"
UPL_APP=0 # 0 = Use cadaver for transferring, 1 = use curl

# GPG
GPGKEY=0 # 0 = use passphrase, 1 = use keyfile
GPGFILE="/path/to/gpgkeyfile"
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
PATH_CURL="/usr/bin/curl"

###
# Stop editing here, script start
###

printf "%s" "
################################
## $APP_NAME $APP_VER         ##
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
# Check whether cadaver is set
if [ ! -f /var/cpanel/backuprunning ]; then
	echo "ERROR: WHM is still busy with the backup"
    exit 1
else
    echo "# WHM Backup: Not running       #"
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

echo "NOTICE: WHMBackup-to-Stack commences!" 

# Make a small and neat package
$PATH_TAR -zcvf $UNSEC_FILE $WHM_FOLDER >> "$LOGFILE"

# I can haz GPG encryptz?
$PATH_GPG --yes --batch --passphrase=$GPGPASS -c $BACK_DIR/backup_$NOW.tar.gz

# Transfer the GPG encrypted file to TransIP Stack
$PATH_CAD -t <<EOF
open https://$STACK_USER.stackstorage.com/remote.php/webdav
cd $STACK_DIR
put $BACK_DIR/backup_$NOW.tar.gz.gpg ./backup_$NOW.tar.gz.gpg
quit
EOF

echo "Delete old backups" 

if [ "${CLEANUP}" = "1" ] then
	echo "Deleting obsolete backup files" >> "$LOGFILE"
	find $BACK_DIR -name "*.tar.gz.gpg" -exec rm {} \; > /dev/null 2>&1
	find $BACK_DIR -mtime +1 -name "*.tar.gz" -exec rm {} \; > /dev/null 2>&1
	echo "Done, the backup is succesfully encrypted and transferred to Stack"
else
	echo "Done, the backup is succesfully encrypted and transferred to Stack"
fi
exit 0;
