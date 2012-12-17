#!/bin/env bash

# creates mysql backups of every db
# keeps history of 7 versions (7 is oldest)
# rotates the versions

# (c) Thomas Mouzinho, founder@foundit.ch

HOST=`hostname`
PATH=$PATH:/usr/bin
MYSQL_BIN_PATH=/usr/bin
DEST_PATH=/path/to/backup/directory
USER=your_username_here
PASSWORD=your_password_here
NIGHTLY_SUFFIX=nightly

function rotate {
  echo "Rotating "$database
  if [ -f "$1.7" ]; then rm -f "$1.7"; fi
  if [ -f "$1.6" ]; then mv -f "$1.6" "$1.7"; fi
  if [ -f "$1.5" ]; then mv -f "$1.5" "$1.6"; fi
  if [ -f "$1.4" ]; then mv -f "$1.4" "$1.5"; fi
  if [ -f "$1.3" ]; then mv -f "$1.3" "$1.4"; fi
  if [ -f "$1.2" ]; then mv -f "$1.2" "$1.3"; fi
  if [ -f "$1.1" ]; then mv -f "$1.1" "$1.2"; fi
  if [ -f "$1" ];   then mv -f "$1"   "$1.1"; fi
}

function dump {
  echo "Backing up "$database
  $MYSQL_BIN_PATH/mysqldump \
  --force \
  --add-drop-database \
  --add-drop-table \
  --opt \
  --user=$USER \
  --password=$PASSWORD \
  $1 \
  > $DEST_PATH/$1
}

function backup {
  echo "Overriding "$1_$NIGHTLY_SUFFIX
  $MYSQL_BIN_PATH/mysql --force --user=$USER --password=$PASSWORD $1_$NIGHTLY_SUFFIX < $DEST_PATH/$1
}

echo "Starting at: "`date`
cd $DEST_PATH

for database in `$MYSQL_BIN_PATH/mysql --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" -B --column-names=false`; do
  if [[ ! $database =~ ^.+_${NIGHTLY_SUFFIX}$|^information_schema$|^mysql$|^.+_bck.*$ ]] ; then
    echo
    echo $database
    rotate $database
    dump $database
    backup $database
  fi
done


echo
echo "Done at: "`date`

exit 0;
