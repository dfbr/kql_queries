#!/usr/bin/env bash
# Generates docs/page/N/index.html stubs so the home page lists the newest
# FIRST_PAGE entries and each later page lists PER_PAGE entries.
# The stubs only carry a page number; the listing itself is done in Liquid
# (docs/_includes/post-list.html), so the counts here only decide which
# page URLs exist. Keep FIRST_PAGE/PER_PAGE in step with docs/_config.yml.
set -euo pipefail

FIRST_PAGE=${FIRST_PAGE:-5}
PER_PAGE=${PER_PAGE:-10}
DOCS_DIR=${1:-docs}

count=0
for dir in "$DOCS_DIR/_posts" "$DOCS_DIR/_notes"; do
  [ -d "$dir" ] || continue
  while IFS= read -r -d '' f; do
    # Jekyll skips files starting with "_" and posts marked unpublished.
    grep -qE '^published:[[:space:]]*false' "$f" && continue
    count=$((count + 1))
  done < <(find "$dir" -type f \( -name '*.md' -o -name '*.markdown' -o -name '*.html' \) ! -name '_*' -print0)
done

if [ "$count" -le "$FIRST_PAGE" ]; then
  pages=1
else
  pages=$(( 1 + (count - FIRST_PAGE + PER_PAGE - 1) / PER_PAGE ))
fi

rm -rf "$DOCS_DIR/page"
for ((n = 2; n <= pages; n++)); do
  mkdir -p "$DOCS_DIR/page/$n"
  cat > "$DOCS_DIR/page/$n/index.html" <<STUB
---
layout: listing
title: "Notes – page $n"
page_number: $n
permalink: /page/$n/
---
STUB
done

echo "Entries: $count, pages: $pages"
