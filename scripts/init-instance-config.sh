#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${MW_SCRIPTS:-$REPO_ROOT/scripts}"
INSTANCES_DIR="${MW_CONFIG:-$REPO_ROOT/instances}"
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/$(basename "$0").log" 2>&1

usage() {
    echo "Usage: $0 --instance NAME [--interactive]"
    exit 1
}

INSTANCE=""
INTERACTIVE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --instance)
            INSTANCE="$2"; shift 2;;
        --interactive)
            INTERACTIVE=1; shift;;
        *) usage;;
    esac
done

if [[ -z "$INSTANCE" && $INTERACTIVE -eq 0 ]]; then
    usage
fi

if [[ $INTERACTIVE -eq 1 ]]; then
    read -p "Instance name: " INSTANCE
    read -p "Webroot [/var/www/html/$INSTANCE]: " WEBROOT
    WEBROOT="${WEBROOT:-/var/www/html/$INSTANCE}"
    read -p "Script path [/$INSTANCE]: " SCRIPT_PATH
    SCRIPT_PATH="${SCRIPT_PATH:-/$INSTANCE}"
    read -p "MediaWiki version [1.43.3]: " MW_VERSION
    MW_VERSION="${MW_VERSION:-1.43.3}"
    read -p "DB name [${INSTANCE}_db]: " DB_NAME
    DB_NAME="${DB_NAME:-${INSTANCE}_db}"
    read -p "DB user [${INSTANCE}_user]: " DB_USER
    DB_USER="${DB_USER:-${INSTANCE}_user}"
    read -p "DB pass [changeMe]: " DB_PASS
    DB_PASS="${DB_PASS:-changeMe}"
    read -p "Admin user [admin]: " ADMIN_USER
    ADMIN_USER="${ADMIN_USER:-admin}"
    read -p "Admin pass [changeMe]: " ADMIN_PASS
    ADMIN_PASS="${ADMIN_PASS:-changeMe}"
    read -p "Admin email [admin@example.com]: " ADMIN_EMAIL
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
else
    WEBROOT="/var/www/html/$INSTANCE"
    SCRIPT_PATH="/$INSTANCE"
    MW_VERSION="1.43.3"
    DB_NAME="${INSTANCE}_db"
    DB_USER="${INSTANCE}_user"
    DB_PASS="changeMe"
    ADMIN_USER="admin"
    ADMIN_PASS="changeMe"
    ADMIN_EMAIL="admin@example.com"
fi

mkdir -p "$INSTANCES_DIR/$INSTANCE"
CONF="$INSTANCES_DIR/$INSTANCE/instance.conf"

if [[ -f "$CONF" ]]; then
    echo "Config $CONF already exists" >&2
    exit 1
fi

cat > "$CONF" <<CONFIG
INSTANCE_NAME: $INSTANCE
WEBROOT: $WEBROOT
SCRIPT_PATH: $SCRIPT_PATH
MW_VERSION: $MW_VERSION
DB_NAME: $DB_NAME
DB_USER: $DB_USER
DB_PASS: $DB_PASS
ADMIN_USER: $ADMIN_USER
ADMIN_PASS: $ADMIN_PASS
ADMIN_EMAIL: $ADMIN_EMAIL
CONFIG

echo "Created $CONF"
