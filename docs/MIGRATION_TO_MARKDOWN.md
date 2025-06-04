# Migrating existing pages to Markdown

To convert existing DokuWiki pages (`*.txt`) to Markdown you need
[Pandoc](https://pandoc.org/) installed. The script below processes
all pages below `data/pages` and keeps a backup of each file:

```sh
#!/bin/sh
set -e
find data/pages -name '*.txt' -type f | while read -r f; do
    cp "$f" "$f.bak"
    pandoc -f dokuwiki -t markdown "$f.bak" -o "$f"
done
```

Run it from the root of your installation. Once you verified the
result you can remove the `.bak` files.


