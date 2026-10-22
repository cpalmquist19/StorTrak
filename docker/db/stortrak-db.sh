#!/bin/sh
# Database maintenance helper, mounted on the db container's PATH as
# `stortrak-db` and called by the Makefile. All shell quoting lives here, so the
# recipes behave the same whether make runs them with sh or cmd.exe.
#
#   stortrak-db recreate          drop and recreate the app database
#   stortrak-db load < file.sql   run SQL from stdin against it
set -eu

export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"

case "${1:-}" in
    recreate)
        mysql -uroot -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\`;"
        ;;
    load)
        exec mysql -uroot "$MYSQL_DATABASE"
        ;;
    *)
        echo "usage: stortrak-db recreate | load < file.sql" >&2
        exit 64
        ;;
esac
