# WHMBackup-to-Stack
A shell script to encrypt WHM backups using GPG and send them off to TransIP Stack for redundancy purposes.

### Usage
1. Clone the repository to the WHM server.
2. Set the variables in the shell script
3. Set the script executable (`chmod +x whm2stack.sh`)
4. Run it: `./whm2stack.sh` or _set a daily cronjob for it_

### Troubleshooting

**Q: What are the dependencies?**

A: This script relies on GPG, tar and Cadaver. Sure, it is possible to use curl's `PUT` functionality, but in my experience, Cadaver plays a bit nicer with the available resources

**Q: The cronjob fails miserably**

A: First of all, check the log file, which is set in the variables. Please make sure that the script runs _after_ the backup job is done. This might take some time, depending on the amount that needs to be backupped. By default, WHM backups run at 2AM. Personally, I set this script to run at 4AM.

**Q: Anything else I should know?**

A: This script solely focusses on WHM, not on cPanel. You'll need root access to the server in question (you'll need to be able to access `/backup`. A per-user script for cPanel is in the making - for which you won't need root or shell access for that matter. There already is a [PHP script](https://github.com/babarnazmi/cpanel-Fullbackup) that can accomplish this, but it doesn't use encryption, just plain-text FTP, so I'd recommend against using it.

If you run into trouble, have some questions/remarks, please, do not hestitate to open an issue. Thank you.