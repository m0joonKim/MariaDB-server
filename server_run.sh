#!/bin/bash

export MARIADB_SRC=$(pwd)
export MARIADB_BUILD=$(pwd)/build
export PATH="$MARIADB_BUILD/extra:$PATH"
export MYSQL_SOCK="/mnt/mariadb/mariadb.sock"

# 깨끗이 초기화
sudo pkill -TERM mariadbd; sleep 2; sudo pkill -KILL mariadbd
sudo rm -rf /mnt/mariadb 
sudo ls /mnt/
sudo mkdir -p /mnt/mariadb
sudo chown root:root /mnt/mariadb
sudo chmod 750 /mnt/mariadb


# 1) init (base+rocksdb 옵션 포함한 동일 cnf)
sudo "$MARIADB_BUILD/scripts/mariadb-install-db" \
  --srcdir="$MARIADB_SRC" \
  --datadir=/mnt/mariadb \
  --defaults-file="$MARIADB_SRC/mariadb.cnf" \
  --auth-root-authentication-method=normal

sleep 5

# 2) 서버 실행 (한 번만 띄움)
sudo "$MARIADB_BUILD/sql/mariadbd" \
  --defaults-file="$MARIADB_SRC/mariadb.cnf" \
  --plugin-dir="$MARIADB_BUILD/storage/rocksdb" \
  --plugin-load-add="ha_rocksdb.so"\
  --socket=$MYSQL_SOCK \
  --pid-file=/mnt/mariadb/mariadb.pid \
  --log-error=/mnt/mariadb/mariadb.err \
  --port=3307 \
  &



sudo tail -f /mnt/mariadb/mariadb.err
