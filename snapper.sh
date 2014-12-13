#!/bin/bash

# Simple BTRFS rolling snapshot script.  
# 2014 - Marvin Curlee - marvin@mcurlee.com - http://mcurlee.com
# The intent is for this script to run once per day.  For more frequent runs, change the date format (see below)

# Adjust for your env
PATH=/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin


# set script params

# set log file path
LOGFILE=/scripts/snapper-logfile.txt

# select the subvolume to snapshot
SUBPATH="/"

# select the location for the snapshots
SNAPPATH="/"

# how many to keep in rotation
MAXSNAPS=30


# start script

echo "START OF JOB" >> $LOGFILE
echo "--------------" >> $LOGFILE
echo `date` >> $LOGFILE

# create new snapshot
# change date format if you need more than one snapshot per day, otherwise you will have name conflicts
btrfs sub snap -r "$SUBPATH" "$SNAPPATH"/.snapshot`date +%m%d%Y` >> $LOGFILE 2>&1


# make sure the new snapshow worked, otherwise exit
test $? -eq 0 || exit 1 


# find the number of current snapshots
NUMSNAPS=`btrfs sub list -s "$SUBPATH" | wc -l`


# this loop will make sure that we only have the max number of snaps (as defined in the params)

while [ $NUMSNAPS -gt $MAXSNAPS ]

  do
    # place the target snapshot name (14th token of the first line) in a var
    TARGETSNAP=`btrfs sub list -s $SNAPPATH | awk '{print $14}' | head -1` 
    
    # make sure the word snap appears in this var as a sanity check
    echo $TARGETSNAP | grep -qi 'snap'  || exit 1

    # now delete the target snapshot and make sure it did not error out
    btrfs sub delete "$SNAPPATH"/"$TARGETSNAP" >> $LOGFILE 2>&1 
    test $? -eq 0 || exit 1 

    # re-calculate the new number of snapshots
    NUMSNAPS=`btrfs sub list -s "$SUBPATH" | wc -l` 

  done


echo "END OF JOB" >> $LOGFILE
echo "--------------" >> $LOGFILE
echo `date` >> $LOGFILE

# end script
