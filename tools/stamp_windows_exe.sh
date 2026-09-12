#!/usr/bin/env bash
# Replace the Godot Engine identity inside the Windows exe with Beramed / Kiko.
# Unsigned games that still say "CompanyName=Godot Engine" are a common Defender false positive.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXE="${1:-$ROOT/KikoWildFuryMatajava.exe}"
WINRES="$(command -v go-winres || true)"
if [[ -z "$WINRES" ]]; then
  WINRES="${HOME}/go/bin/go-winres"
fi
if [[ ! -x "$WINRES" ]]; then
  echo "go-winres not found. Install: go install github.com/tc-hib/go-winres@latest" >&2
  exit 1
fi
if [[ ! -f "$EXE" ]]; then
  echo "missing $EXE" >&2
  exit 1
fi
cp -f "$ROOT/assets/ui/kiko_app_icon.png" "$ROOT/tools/winres/icon.png"
BEFORE="$(stat -c%s "$EXE")"
(
  cd "$ROOT/tools/winres"
  "$WINRES" patch --in winres.json --delete --no-backup \
    --product-version 1.0.0.0 --file-version 1.0.0.0 \
    --authenticode ignore \
    "$EXE"
)
AFTER="$(stat -c%s "$EXE")"
echo "stamped $EXE  ${BEFORE} -> ${AFTER} bytes"
if [[ "$AFTER" -lt 80000000 ]]; then
  echo "ERROR: exe shrank too much; PCK overlay may have been lost" >&2
  exit 1
fi
