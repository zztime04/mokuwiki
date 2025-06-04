#!/bin/sh
# Convert all DokuWiki pages to Markdown using pandoc

set -e
find data/pages -name '*.txt' -type f | while read -r f; do
    cp "$f" "$f.bak"
    pandoc -f dokuwiki -t markdown "$f.bak" -o "$f"
done

