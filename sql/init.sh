#!/bin/bash
set -xe
set -o pipefail

CURRENT_DIR=$(cd $(dirname $0);pwd)
export MYSQL_HOST=10.0.0.102
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_USER=${MYSQL_USER:-isucari}
export MYSQL_DBNAME=${MYSQL_DBNAME:-isucari}
export MYSQL_PWD=${MYSQL_PASS:-isucari}
export LANG="C.UTF-8"
cd $CURRENT_DIR

cat 01_schema.sql 02_categories.sql initial.sql commit.sql | mysql --defaults-file=/dev/null -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER $MYSQL_DBNAME
