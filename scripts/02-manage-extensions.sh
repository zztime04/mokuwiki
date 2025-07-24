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

CONF="$INSTANCES_DIR/$INSTANCE/extensions.conf"
INC_CONF="$INSTANCES_DIR/$INSTANCE/instance.conf"

if [[ ! -f "$CONF" ]] || [[ ! -f "$INC_CONF" ]]; then
    echo "Configuration not found for $INSTANCE" >&2
    exit 1
fi

get_instance() { grep "^$1:" "$INC_CONF" | awk -F': *' '{print $2}'; }
WEBROOT="$(get_instance WEBROOT)"

install_ext() {
    local name="$1" type="$2" source="$3"
    if [[ "$type" == "composer" ]]; then
        sudo -u wiki-deploy composer require "$source" --working-dir="$WEBROOT"
    else
        tmp=$(mktemp)
        wget -qO "$tmp" "$source"
        mkdir -p "$WEBROOT/extensions/$name"
        tar --strip-components=1 -xzf "$tmp" -C "$WEBROOT/extensions/$name"
        rm -f "$tmp"
    fi
    if ! grep -q "wfLoadExtension( '$name' )" "$WEBROOT/LocalSettings.php"; then
        echo "wfLoadExtension( '$name' );" >> "$WEBROOT/LocalSettings.php"
    fi
}

section=""
name=""; type=""; source=""
while IFS= read -r line; do
    case "$line" in
        SHARED_EXTENSIONS:*) section="shared";;
        EXTENSIONS:*) section="ext";;
        "  - name:"*) name="$(echo "$line" | cut -d':' -f2 | xargs)";;
        "    type:"*) type="$(echo "$line" | cut -d':' -f2 | xargs)";;
        "    source:"*) source="$(echo "$line" | cut -d':' -f2 | xargs)"; install_ext "$name" "$type" "$source"; name="";;
    esac
done < "$CONF"

echo "[extensions] Completed for $INSTANCE"
