#!/usr/bin/env bash
# Build a installable .plasmoid zip for GitHub Releases.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(python3 - <<'PY'
import json
print(json.load(open("metadata.json"))["KPlugin"]["Version"])
PY
)"

OUT_DIR="${1:-dist}"
mkdir -p "$OUT_DIR"
ARTIFACT="$OUT_DIR/plasma-openmeteo-weather-${VERSION}.plasmoid"
rm -f "$ARTIFACT"

# Match prior release layout: package root with metadata + contents (+ notices).
zip -r -q "$ARTIFACT" \
  metadata.json \
  contents \
  NOTICE.md \
  README.md \
  -x 'contents/locale/*' \
  -x '*~' \
  -x '*.bak' \
  -x '*.orig' \
  -x '*.rej'

echo "$ARTIFACT"
