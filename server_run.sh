#!/bin/bash

set -x

export MARIADB_SRC=$(pwd)
export MARIADB_BUILD=$(pwd)/build
export PATH="$MARIADB_BUILD/extra:$PATH"
export MARIADB_="/mnt/990pro/mariadb"
export MYSQL_SOCK="$MARIADB_/mariadb.sock"
CNF_FILE="${MARIADB_CNF:-${1:-$MARIADB_SRC/cnf/mariadb.cnf}}"

if [ ! -f "$CNF_FILE" ]; then
  echo "ERROR: cnf not found: $CNF_FILE" >&2
  exit 1
fi
echo "Using CNF_FILE: $CNF_FILE"
# 깨끗이 초기화
sudo pkill -TERM mariadbd; sleep 2; sudo pkill -KILL mariadbd
sudo rm -rf "$MARIADB_"
sudo ls /mnt/990pro/
sudo mkdir -p "$MARIADB_"
sudo chown root:root "$MARIADB_"
sudo chmod 750 "$MARIADB_"

sudo "$MARIADB_BUILD/scripts/mariadb-install-db" \
  --srcdir="$MARIADB_SRC" \
  --datadir="$MARIADB_" \
  --defaults-file="$CNF_FILE" \
  --auth-root-authentication-method=normal

sleep 5

sudo "$MARIADB_BUILD/sql/mariadbd" \
  --defaults-file="$CNF_FILE" \
  --plugin-dir="$MARIADB_BUILD/storage/rocksdb" \
  --plugin-load-add="ha_rocksdb.so"\
  --socket=$MYSQL_SOCK \
  --pid-file=$MARIADB_/mariadb.pid \
  --log-error=$MARIADB_/mariadb.err \
  --port=3307 \
  &


TARGET="ready for connections."
sudo tail -F "$MARIADB_/mariadb.err" | grep -m 1 "$TARGET"

sleep 2

sudo -u root "$MARIADB_BUILD/client/mariadb" \
  --socket="$MYSQL_SOCK" \
  -e "SELECT VERSION();"
  
sleep 2

sudo -u root "$MARIADB_BUILD/client/mariadb" \
  --socket="$MYSQL_SOCK" \
  -e "SHOW ENGINES;" | grep -i rocks
  
sleep 2

# RocksDB 플러그인 상태 확인 (참고)
sudo -u root "$MARIADB_BUILD/client/mariadb" \
  --socket="$MYSQL_SOCK" \
  -e "
SELECT PLUGIN_NAME, PLUGIN_STATUS
FROM information_schema.PLUGINS
WHERE PLUGIN_NAME LIKE 'rocks%';
"

sleep 2

sudo -u root "$MARIADB_BUILD/client/mariadb" \
  --socket="$MYSQL_SOCK" \
  -e "
SET GLOBAL default_storage_engine=ROCKSDB;
CREATE DATABASE IF NOT EXISTS sbtest;
"

sleep 2

if ! sudo -u root "$MARIADB_BUILD/client/mariadb" \
  --socket="$MYSQL_SOCK" \
  -e "SHOW VARIABLES LIKE 'default_storage_engine';" \
  | rg -q "default_storage_engine[[:space:]]+ROCKSDB"
then
  echo "ERROR: default_storage_engine is not ROCKSDB" >&2
  exit 1
fi
echo "default_storage_engine is ROCKSDB, server_run.sh COMPLETED."
