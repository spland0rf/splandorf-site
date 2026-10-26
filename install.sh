#!/usr/bin/env bash
# Publish the homepage and the routing on the FRONT VM (the one www.splandorf.com points at). Run as root:
#   sudo bash install.sh
# Safe to re-run after every change to this repository. Settings live in /etc/splandorf-site/env.
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" = 0 ] || { echo "Run this as root: sudo bash $0"; exit 1; }

ENV_DIR=/etc/splandorf-site
ENV_FILE=$ENV_DIR/env
mkdir -p "$ENV_DIR"
if [ ! -f "$ENV_FILE" ]; then
  PURPLE_IP="${PURPLE_IP:-}"
  if [ -z "$PURPLE_IP" ] && [ -t 0 ]; then
    read -r -p "purple-1's INTERNAL IP address (setup.sh on purple-1 printed it): " PURPLE_IP
  fi
  cat > "$ENV_FILE" <<ENVF
SITE_HOST=${SITE_HOST:-www.splandorf.com}
APEX=${APEX:-splandorf.com}
PURPLE_UPSTREAM=${PURPLE_IP:-127.0.0.1}:8000
ENVF
fi
set -a; . "$ENV_FILE"; set +a

mkdir -p /var/www/site && cp -r site/. /var/www/site/ && chmod -R a+rX /var/www/site
TMP=$(mktemp)
sed -e "s/__HOST__/$SITE_HOST/g" -e "s/__APEX__/$APEX/g" -e "s/__PURPLE_UPSTREAM__/$PURPLE_UPSTREAM/g" Caddyfile > "$TMP"
if ! caddy validate --adapter caddyfile --config "$TMP" >/dev/null 2>&1; then
  caddy validate --adapter caddyfile --config "$TMP" || true
  rm -f "$TMP"; echo "The new routing is not valid; the running site was left unchanged."; exit 1
fi
install -m 644 "$TMP" /etc/caddy/Caddyfile && rm -f "$TMP"
systemctl reload caddy || systemctl restart caddy

echo "Published. Homepage: https://$SITE_HOST/   Conlang: https://$SITE_HOST/conlang/   Purple: https://$SITE_HOST/purple/"
if curl -fsS --max-time 4 "http://$PURPLE_UPSTREAM/api/health" >/dev/null; then
  echo "purple-1 answers at $PURPLE_UPSTREAM."
else
  echo "Note: purple-1 does not answer at $PURPLE_UPSTREAM yet (not installed, stopped, or the firewall rule is missing)."
  echo "      To change the address: sudo nano $ENV_FILE  then  sudo bash $0"
fi
