#!/bin/sh
set -e

: "${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD manquante}"
: "${MARIADB_DATABASE:?MARIADB_DATABASE manquante}"
: "${MARIADB_USER:?MARIADB_USER manquante}"
: "${MARIADB_PASSWORD:?MARIADB_PASSWORD manquante}"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[mariadb] db vide -> init"

  mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db

    cat > /tmp/init.sql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

  mariadbd --user=mysql --bootstrap < /tmp/init.sql
  rm -f /tmp/init.sql

  echo "[mariadb] Init terminé"
else
  echo "[mariadb] db trouvé -> démarrage"
fi

exec "$@"