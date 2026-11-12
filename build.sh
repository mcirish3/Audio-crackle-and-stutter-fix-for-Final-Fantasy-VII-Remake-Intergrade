#!/usr/bin/env bash
# Builds the user-facing release zip into dist/.
# Layout inside the zip:
#   Smooth Midgar/
#     1 - Install (run once).bat
#     2 - Uninstall.bat
#     Epic Games - Play FF7R.bat
#     README.txt
#     files/  (PowerShell scripts + Engine.ini template)
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(tr -d '[:space:]' < VERSION)"
NAME="Smooth Midgar"
STAGE="dist/stage/$NAME"
ZIP="dist/FF7R-Legacy-CPU-Tuning-v${VERSION}.zip"  # name the release workflow uploads

# The installer and readme carry the version too; make sure they agree.
grep -q "\$Version = '${VERSION}'" src/scripts/Install-FF7RTuning.ps1 \
  || { echo "Version mismatch: update \$Version in Install-FF7RTuning.ps1 to ${VERSION}"; exit 1; }
grep -q "v${VERSION}" src/README.txt \
  || { echo "Version mismatch: update the version line in src/README.txt to v${VERSION}"; exit 1; }

# Windows PowerShell 5.1 misreads non-ASCII in BOM-less scripts.
if grep -nP '[^\x00-\x7F]' src/scripts/* src/launchers/* src/README.txt; then
  echo "Non-ASCII characters found above; remove them."; exit 1
fi

rm -rf dist
mkdir -p "$STAGE/files"
cp src/launchers/*.bat "$STAGE/"
cp src/README.txt "$STAGE/"
cp src/scripts/* "$STAGE/files/"

# Force Windows line endings in everything shipped.
find "$STAGE" -type f \( -name '*.bat' -o -name '*.ps1' -o -name '*.ini' -o -name '*.txt' \) \
  -exec sed -i 's/\r$//; s/$/\r/' {} +

(cd dist/stage && zip -qr -X "../$(basename "$ZIP")" "$NAME")
rm -rf dist/stage
echo "Built $ZIP"
