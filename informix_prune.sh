#!/bin/bash

. /usr/local/bin/informix_inf.env

HOME_DIR=$BASEDIR/informix

DIRS="
"


FILES="
edition.jar
ids_install
*.log
"

EXTRA_FILES="
"

# Removed, Possibly put back in
# bin/dbaccessdemo*

for i in $DIRS
do
echo rm -rf $HOME_DIR/$i
rm -rf $HOME_DIR/$i
done

for i in $FILES
do
echo rm -f $HOME_DIR/$i
rm -f $HOME_DIR/$i
done



for i in $EXTRA_FILES
do
echo rm -f $HOME_DIR/$i
rm -f $HOME_DIR/$i
done




