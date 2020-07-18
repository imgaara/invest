#!/bin/bash

DIR="$(cd "$(dirname "$0")"; pwd -P)"
CRAWL_HOME="$DIR/../../../TT_Fund"
NAV_DIR="$DIR/../navs"
TOOLS_DIR="$DIR/../tools"

date=$(date '+%Y%m%d')

set -euo pipefail

echo "+ export watched nav..."
$TOOLS_DIR/mongo_export_nav.sh

echo "+ calculating tradelines..."
/Users/kangyu/.pyenv/shims/python3 $TOOLS_DIR/tradeline.py

echo "+ pushing navs..."
pushd $DIR/..
git ci . -m "update navs"
git push
popd
