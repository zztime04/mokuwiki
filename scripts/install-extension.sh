#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${MW_SCRIPTS:-$REPO_ROOT/scripts}"
INSTANCES_DIR="${MW_CONFIG:-$REPO_ROOT/instances}"
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/$(basename "$0").log" 2>&1

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <instance> <url|pkg> <extname>" >&2
    exit 1
fi

INSTANCE="$1"
SRC="$2"
EXTNAME="$3"

CONF="$INSTANCES_DIR/$INSTANCE/instance.conf"
if [[ ! -f "$CONF" ]]; then
    echo "$CONF not found" >&2
    exit 1
fi

get_instance() { grep "^$1:" "$CONF" | awk -F': *' '{print $2}'; }
WEBROOT="$(get_instance WEBROOT)"

if [[ "$SRC" =~ ^https?:// || "$SRC" =~ \.tar\.gz$ ]]; then
    tmp=$(mktemp)
    wget -qO "$tmp" "$SRC"
    mkdir -p "$WEBROOT/extensions/$EXTNAME"
    tar --strip-components=1 -xzf "$tmp" -C "$WEBROOT/extensions/$EXTNAME"
    rm -f "$tmp"
else
    sudo -u wiki-deploy composer require "$SRC" --working-dir="$WEBROOT"
fi

if ! grep -q "wfLoadExtension( '$EXTNAME' )" "$WEBROOT/LocalSettings.php"; then
    echo "wfLoadExtension( '$EXTNAME' );" >> "$WEBROOT/LocalSettings.php"
fi

echo "[install-extension] Installed $EXTNAME for $INSTANCE"
