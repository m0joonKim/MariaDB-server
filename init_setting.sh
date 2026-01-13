#!/bin/bash
export MARIADB_SRC=$(pwd)
export MARIADB_BUILD=$(pwd)/build
export PATH="$MARIADB_BUILD/extra:$PATH"
export MYSQL_SOCK="/mnt/mariadb/mariadb.sock"

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

sudo -u root "$MARIADB_BUILD/client/mariadb" \
  --socket="$MYSQL_SOCK" \
  -e "
SHOW VARIABLES LIKE 'default_storage_engine';
"
