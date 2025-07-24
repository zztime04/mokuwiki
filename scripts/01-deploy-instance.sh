#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${MW_SCRIPTS:-$REPO_ROOT/scripts}"
INSTANCES_DIR="${MW_CONFIG:-$REPO_ROOT/instances}"
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/$(basename "$0").log" 2>&1

usage() {
    echo "Usage: $0 --instance NAME"
    exit 1
}

INSTANCE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --instance)
            INSTANCE="$2"; shift 2;;
        *) usage;;
    esac
done

if [[ -z "$INSTANCE" ]]; then
    usage
fi

CONF="$INSTANCES_DIR/$INSTANCE/instance.conf"
if [[ ! -f "$CONF" ]]; then
    echo "$CONF not found" >&2
    exit 1
fi

get() { grep "^$1:" "$CONF" | awk -F': *' '{print $2}'; }

INSTANCE_NAME="$(get INSTANCE_NAME)"
WEBROOT="$(get WEBROOT)"
SCRIPT_PATH="$(get SCRIPT_PATH)"
MW_VERSION="$(get MW_VERSION)"
DB_NAME="$(get DB_NAME)"
DB_USER="$(get DB_USER)"
DB_PASS="$(get DB_PASS)"
ADMIN_USER="$(get ADMIN_USER)"
ADMIN_PASS="$(get ADMIN_PASS)"
ADMIN_EMAIL="$(get ADMIN_EMAIL)"

ARCHIVE="/opt/mediawiki/mediawiki-${MW_VERSION}.tar.gz"

echo "[deploy] extracting $ARCHIVE to $WEBROOT"
rm -rf "$WEBROOT"
mkdir -p "$WEBROOT"
tar --strip-components=1 -xzf "$ARCHIVE" -C "$WEBROOT"
chown -R www-data:www-data "$WEBROOT"

mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"

sudo -u www-data php "$WEBROOT/maintenance/install.php" \
  --dbname "$DB_NAME" --dbuser "$DB_USER" --dbpass "$DB_PASS" \
  --scriptpath "$SCRIPT_PATH" --server "http://localhost" \
  "$INSTANCE_NAME" "$ADMIN_USER" --pass "$ADMIN_PASS" --email "$ADMIN_EMAIL"

VCONF="/etc/apache2/conf-available/${INSTANCE}.conf"
cat > "$VCONF" <<APACHE
Alias $SCRIPT_PATH $WEBROOT
<Directory $WEBROOT>
    Require all granted
</Directory>
APACHE

a2enconf "${INSTANCE}.conf"
service apache2 reload

echo "[deploy] Instance $INSTANCE deployed"
