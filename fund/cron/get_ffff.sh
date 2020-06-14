#!/bin/bash

DIR="$(cd "$(dirname "$0")"; pwd -P)"
CRAWL_HOME="$DIR/../../../TT_Fund"
NAV_DIR="$DIR/../navs"
TOOLS_DIR="$DIR/../tools"

date=$(date '+%Y%m%d')

set -euo pipefail

echo "+ getting funds...end date: $date"

pushd "$CRAWL_HOME"
scrapy crawl fund_earning || {
  echo "- failed to crawl fund"
  exit 1
}
echo "+ fund crawled!"

echo "+ importing funds to mongodb..."
mongoimport -d f -c nav --type csv --file "$CRAWL_HOME/fund_earning_perday_${date}.csv" --headerline --mode=upsert || {
  echo "- failed to import funds to mongodb"
}
popd

while read line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  $TOOLS_DIR/mongo_export_nav.sh "$line" || {
    echo "- failed to export fund $line from mongodb"
  }
done < "$TOOLS_DIR/watch_funds.txt"
