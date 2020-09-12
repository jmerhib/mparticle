#!/bin/bash
#crontab entry
#0 0 * * * /root/scripts/daily_backup.sh >/dev/null 2>&1
#------Define Varibles
BACKUPDIR=/var/log
S3=arn:aws:s3:::jmerhib
S3_SHORT=s3://jmerhib
BACKUPDATE=`date +%F-%H%M-%S`
TARFILE=Daily_Backup_${BACKUPDATE}.tar.gz
LOGFILE=/backup/daily_backup.out
TOMAIL="justin.merhib@gmail.com"
#------Ensure /backups exists
>$LOGFILE #blank out log file
ls -l /backup > /dev/null 2>&1
if [ $? != "0" ]
then
  mkdir /backup
  echo "/backup did not exist, directory structure created" >> $LOGFILE 2>&1
fi
#------Main Script
echo "Archiving $BACKUPDIR" | tee -a $LOGFILE 2>&1
cd /backup
tar czfv $TARFILE $BACKUPDIR/*  | tee -a $LOGFILE 2>&1
echo -e "Backup complete\nPushing $TARFILE to $S3" | tee -a $LOGFILE 2>&1
aws s3 cp --only-show-errors $TARFILE $S3_SHORT | tee -a $LOGFILE 2>&1
echo -e "$TARFILE uploaded to $S3\n Verifying file uploaded to $S3" | tee -a $LOGFILE 2>&1
aws s3 ls $S3_SHORT/$TARFILE | tee -a $LOGFILE 2>&1
if [ $? != "0" ]
then
  echo "***********$TARFILE FAILED TO UPLOAD TO $S3***********" | tee -a $LOGFILE 2>&1
  mailx -s "Daily Backup FAILED on `hostname`" $MAIL < $LOGFILE
else
  echo "$TARFILE uploaded to $S3 successfully" | tee -a $LOGFILE 2>&1
  echo "Purging backups older than 7 days" | tee -a $LOGFILE 2>&1
  find . -name "Daily_Backup*" -mtime +7 -exec  echo "Purging" {} \; | tee -a $LOGFILE 2>&1
  find . -name "Daily_Backup*" -mtime +7 -exec sudo rm {} \; | tee -a $LOGFILE 2>&1
  mailx -s "Daily Backup Completed Successfully on `hostname`" $MAIL < $LOGFILE
fi
