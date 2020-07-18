#!/bin/bash

DIR="$(cd "$(dirname "$0")"; pwd -P)"
CRAWL_HOME="$DIR/../../../TT_Fund"
NAV_DIR="$DIR/../navs"
TOOLS_DIR="$DIR/../tools"

date=$(date '+%Y%m%d')

set -euo pipefail

echo "+ getting funds...end date: $date"

pushd "$CRAWL_HOME"
/Users/kangyu/.pyenv/shims/scrapy crawl fund_earning || {
  echo "- failed to crawl fund"
  exit 1
}
echo "+ fund crawled!"

echo "+ importing funds to mongodb..."
tail -n +1 "$CRAWL_HOME/fund_earning_perday_${date}.csv" | /usr/local/bin/mongoimport -d f -c nav --type csv --columnsHaveTypes --mode=upsert --fields="fund_type.string(),code.string(),name.string(),date.string(),total_day.auto(),net_value.auto(),accumulative_value.auto(),rate_day.auto(),buy_status.string(),sell_status.string(),profit.string()" || {
  echo "- failed to import funds to mongodb"
}
popd

echo "+ export watched nav..."
$TOOLS_DIR/mongo_export_nav.sh

echo "+ calculating tradelines..."
/Users/kangyu/.pyenv/shims/python3 $TOOLS_DIR/tradeline.py

echo "+ pushing navs..."
pushd $DIR/..
git add .
git ci . -m "update navs"
git push
popd
