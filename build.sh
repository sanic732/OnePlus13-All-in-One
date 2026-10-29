#!/bin/sh
# Build release zips: main module and diagnostic module
set -e
cd "$(dirname "$0")"
VER=$(sed -n 's/^version=//p' module.prop)
DVER=$(sed -n 's/^version=//p' diagnostic/module.prop)
mkdir -p out
rm -f "out/OnePlus13-All-in-One_${VER}.zip" "out/OnePlus13-Diagnostic-${DVER}.zip"
zip -r9 "out/OnePlus13-All-in-One_${VER}.zip" \
  META-INF nvbk webroot module.prop system.prop customize.sh post-fs-data.sh service.sh \
  action.sh uninstall.sh LICENSE CREDITS.md CHANGELOG.md README.md
(cd diagnostic && zip -r9 "../out/OnePlus13-Diagnostic-${DVER}.zip" \
  META-INF module.prop customize.sh action.sh diag.sh CHANGELOG.md README.md)
ls -la out
