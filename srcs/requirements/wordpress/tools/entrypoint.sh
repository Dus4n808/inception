#!/bin/sh

set -e

MARIADB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(grep ^WP_ADMIN_PASSWORD= /run/secrets/credentials | cut -d= -f2-)
WP_USER_PASSWORD=$(grep ^WP_USER_PASSWORD= /run/secrets/credentials | cut -d= -f2-)

: "${MARIADB_HOST:?MARIADB_HOST manquante}"
: "${MARIADB_DATABASE:?MARIADB_DATABASE manquante}"
: "${MARIADB_USER:?MARIADB_USER manquante}"
: "${MARIADB_PASSWORD:?MARIADB_PASSWORD manquante}"
: "${WP_URL:?WP_URL manquante}"
: "${WP_TITLE:?WP_TITLE manquante}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER manquante}"
: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD manquante}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL manquante}"
: "${WP_USER:?WP_USER manquante}"
: "${WP_USER_PASSWORD:?WP_USER_PASSWORD manquante}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL manquante}"

mkdir -p /run/php
chown -R www-data:www-data /var/www/html

cd /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then
  echo "[wordpress] pas d'installation -> init"

  until mariadb-admin ping -h"$MARIADB_HOST" \
        -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" --silent 2>/dev/null; do
    echo "[wordpress] attente de mariadb ...."
    sleep 2
  done
  echo "[wordpress] mariadb est prêt"

  wp core download --allow-root

  wp config create --allow-root \
   --dbname="$MARIADB_DATABASE" \
   --dbuser="$MARIADB_USER" \
   --dbpass="$MARIADB_PASSWORD" \
   --dbhost="$MARIADB_HOST" 

  wp core install --allow-root \
   --url="$WP_URL" \
   --title="$WP_TITLE" \
   --admin_user="$WP_ADMIN_USER" \
   --admin_password="$WP_ADMIN_PASSWORD" \
   --admin_email="$WP_ADMIN_EMAIL" \
   --skip-email

  wp user create --allow-root \
   "$WP_USER" "$WP_USER_EMAIL" \
   --user_pass="$WP_USER_PASSWORD" \
   --role=author

  echo "[wordpress] Init terminé"
else
  echo "[wordpress] installation trouvé -> démarrage"
fi

chown -R www-data:www-data /var/www/html

exec "$@"