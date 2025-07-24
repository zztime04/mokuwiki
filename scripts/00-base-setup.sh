#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${MW_SCRIPTS:-$REPO_ROOT/scripts}"
INSTANCES_DIR="${MW_CONFIG:-$REPO_ROOT/instances}"
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/$(basename "$0").log" 2>&1

echo "[00-base-setup] Installing base packages"

apt-get update
apt-get install -y apache2 php php-fpm mariadb-server \
    php-mysql php-intl php-mbstring php-apcu imagemagick \
    wget tar

a2enmod proxy_fcgi setenvif rewrite
systemctl enable --now php*-fpm
systemctl restart apache2

echo "[00-base-setup] Base environment ready"
