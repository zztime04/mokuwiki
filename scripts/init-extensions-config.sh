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

mkdir -p "$INSTANCES_DIR/$INSTANCE"
CONF="$INSTANCES_DIR/$INSTANCE/extensions.conf"

if [[ -f "$CONF" ]]; then
    echo "$CONF already exists" >&2
    exit 1
fi

cat > "$CONF" <<CONF
COMPOSER_VENDOR_DIR: vendor
SHARED_EXTENSIONS:
  - name: VisualEditor
    type: composer
    source: mediawiki/visualeditor:*
EXTENSIONS:
  - name: SemanticMediaWiki
    type: composer
    source: semantic-media-wiki/semantic-media-wiki:~3.3
  - name: CustomSkin
    type: archive
    source: https://example.com/skins/CustomSkin-1.0.2.tar.gz
    version: 1.0.2
CONF

echo "Created $CONF"
