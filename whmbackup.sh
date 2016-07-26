#!/bin/sh
##############################################
### whmbackup.sh v0.1
# Script to automatically send off nightly WHM
# backups to TransIP Stack.
# --------------------------------------------
# More details coming soon

# Edit these variables
gpgpass="your-ultra-secure-GPG-passphrase"
stackuser="your-TransIP-Stack-username"
stackdir="backups/server"

# General variables
now="$(date +'%Y-%m-%d')"
filename="db_backup_$now".gz
backupfolder="/backup/$now"
fullpathbackupfile="$backupfolder/$filename"
logfile="$backupfolder/"backup_log_"$(date +'%Y_%m')".txt

# Make a small, neat package
/usr/bin/tar -zcvf ~/backups/backup_$now.tar.gz $backupfolder

# I can haz encryptz?
/usr/bin/gpg --yes --batch --passphrase=$gpgpass -c /root/backups/backup_$now.tar.gz

/usr/bin/cadaver -t <<EOF
open https://$stackuser.stackstorage.com/remote.php/webdav
cd backups/server
put /root/backups/backup_$now.tar.gz.gpg ./backup_$now.tar.gz.gpg
quit
EOF

echo "Delete old backups" >> "$logfile"

find /root/backups/* -mtime +0 -exec rm -r {} \; > /dev/null 2>&1
find ~/backups/ -name "*.tar.gz.gpg" -exec rm {} \; > /dev/null 2>&1
find ~/backups/ -mtime +1 -name "*.tar.gz" -exec rm {} \; > /dev/null 2>&1

exit 0;
