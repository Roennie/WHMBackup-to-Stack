#!/bin/sh
##################################################
### WHMBackup-to-Stack v0.23-GIT				 #
# Script to automatically send off nightly WHM   #
# backups to TransIP Stack.						 #
# -----------------------------------------------#
# USAGE:										 #
# 1. Edit the variables below					 #
# 2. Make sure the script is executable			 #
# 3. ./whm2stack.sh 							 #
# 4. ???										 #
# 5. PROFIT!									 #
#												 #
# If you experience problems, or have some ideas #
# to enhance this script, please file an issue:	 #
# https://github.com/Roennie/WHMBackup-to-Stack	 #
##################################################

###
# Set these variables to match your preferences
# and environment
###

# FILES & FOLDERS
WORK_DIR=`pwd`
BACK_DIR="$WORK_DIR/backups"
UNSEC_FILE="$BACK_DIR/unsec_backup_$(date +'%Y-%m-%d').gz"
WHM_FOLDER="/backup/$now"
LOGFILE="$WORK_DIR/"backup_log_"$(date +'%Y_%m-%d')".txt

# GPG
GPGKEY=0 # 0 = use passphrase, 1 = use keyfile
GPGFILE="/path/to/gpgkeyfile"
GPGPASS="your-ultra-secure-GPG-passphrase"

# DEPENDENCIES
PATH_TAR="/usr/bin/tar"
PATH_GPG="/usr/bin/gpg"
PATH_CAD="/usr/bin/cadaver"
PATH_CURL="/usr/bin/curl"

# REMOTE
STACK_USER="your-TransIP-Stack-username"
STACK_PASS="your-TransIP-Stack-password"
STACK_DIR="backups/server"

# NOTIFY
NOTIF_RECEIP="Username that gets the report, eg: root"

#TODO: SMTP support
##NOTIF_SENDER="The sender emailaddress"
##NOTIF_SERVER="The SMTP server hostname"
##NOTIF_SRVUSR="The SMTP server login"
##NOTIF_SRVPWD="The SMTP server password"
##NOTIF_USEAUT=1 # 1 = Authenticate, 2 = don't authenticate SMTP
##NOTIF_USETLS=1 # 1 = Use SSL/TLS, 2 = use plaintext

###
# Stop editing here, script start
###

# APPLICATION
APP_NAME="WHMBackup-to-Stack"
APP_VER="0.23-GIT"
UPL_APP=0 # 0 = Use cadaver for transferring, 1 = use curl

NOW="$(date +'%Y-%m-%d')"

ROOT_UID=0

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
# Check whether the running user is root
if [ ! "$UID" -eq "$ROOT_UID" ]; then
    echo "ERROR: whm2stack should run as root!"
    exit 1
else
	echo "# We are running as root, yay!  #"
fi

echo "################################"

# Set PID file location
HOMEDIR=`echo ~ 2> /dev/null`
if [ "${HOMEDIR}" = "" ]; then HOMEDIR="/tmp"; PIDFILE="$HOMEDIR/whm2stack.pid"; fi
# Check whether WHMBackup-to-Stack is already running
if [ -f "${HOMEDIR}/whm2stack.pid" ]; then
	echo "ERROR: WHMBackup-to-Stack seems to be running already, exiting"
	echo "ERROR: WHMBackup-to-Stack exited prematurely, PID file already existed" >> "$LOGFILE"
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

if [ "${CLEANUP}" -eq 1 ]; then
	echo "Deleting obsolete backup files" >> "$LOGFILE"
	find $BACK_DIR -name "*.tar.gz.gpg" -exec rm {} \; > /dev/null 2>&1
	find $BACK_DIR -mtime +1 -name "*.tar.gz" -exec rm {} \; > /dev/null 2>&1
	echo "Done, the backup is succesfully encrypted and transferred to Stack"
else
	echo "Done, the backup is succesfully encrypted and transferred to Stack"
fi

if [ "${NOTIFY}" = "1" ]; then
	echo "Notifying the server administrator" >> "$LOGFILE"
	echo $REPORT | mail -s "[whm2stack] Backup report for $NOW" $NOTIF_RECEIP
fi

exit 0;
