#!/bin/sh
# Database maintenance helper, mounted on the db container's PATH as
# `stortrak-db` and called by the Makefile. All shell quoting lives here, so the
# recipes behave the same whether make runs them with sh or cmd.exe.
#
#   stortrak-db recreate           drop and recreate the app database (as root)
#   stortrak-db load < file.sql    run SQL from stdin against it (as root)
#   stortrak-db query < file.sql   run SQL from stdin as the app user, table output
set -eu

case "${1:-}" in
    recreate)
        export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
        mysql -uroot -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\`;"
        ;;
    load)
        export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
        exec mysql -uroot "$MYSQL_DATABASE"
        ;;
    query)
        export MYSQL_PWD="$MYSQL_PASSWORD"
        exec mysql -u"$MYSQL_USER" --table "$MYSQL_DATABASE"
        ;;
    *)
        echo "usage: stortrak-db recreate | load < file.sql | query < file.sql" >&2
        exit 64
        ;;
esac
