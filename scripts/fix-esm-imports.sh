#!/usr/bin/env bash
# fix-esm-imports.sh — Append .js to relative imports in compiled ESM output.
# Runs as a post-build step so source files stay extension-free.
set -euo pipefail

DIR="${1:-dist}"

# Use Node.js for reliable regex with lookbehinds
node -e "
const fs = require('fs');
const path = require('path');

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.name.endsWith('.js')) fix(full);
  }
}

function fix(file) {
  const src = fs.readFileSync(file, 'utf8');
  // Match: from \"./foo\" or from './foo' where path starts with . and doesn't already have an extension
  const out = src.replace(/(from\s+[\"'])(\.\.?\/[^\"']+?)(?<!\\.js)(?<!\\.json)(?<!\\.mjs)([\"'])/g, '\$1\$2.js\$3');
  if (out !== src) fs.writeFileSync(file, out);
}

walk('$DIR');
console.log('fix-esm-imports: patched .js extensions in $DIR');
"

