#!/bin/sh

set -e

: "${DOMAIN_NAME:?DOMAIN_NAME manquante}"

CRT="/etc/nginx/ssl/inception.crt"
KEY="/etc/nginx/ssl/inception.key"

if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  echo "[nginx] génération du certificat auto-signé pour $DOMAIN_NAME"
  openssl req -x509 -nodes \
   -newkey rsa:2048\
   -days 365 \
   -keyout "$KEY" \
   -out "$CRT" \
   -subj "/C=CH/ST=Vaud/L=Lausanne/O=42/OU=42Lausanne/CN=${DOMAIN_NAME}"\
   -addext "subjectAltName=DNS:${DOMAIN_NAME}" 
  chmod 600 "$KEY"
  echo "[nginx] certificat généré"
else
  echo "[nginx] certificat existant -> démarrage"
fi

nginx -t

exec "$@"