#!/bin/bash


DIR="$(cd "$(dirname "$0")"; pwd -P)"
NAV_DIR="$DIR/../navs"

date=$(date '+%Y%m%d')

set -euo pipefail

function export_watched() {
  code="$1"
  query="{\"code\":{\"\$eq\":\"$code\"}}"
  echo "$query"
  mongoexport -h localhost -d f -c nav --type=csv \
   --fields=fund_type,code,name,date,total_day,net_value,accumulative_value,rate_day,buy_status,sell_status,profit \
   --noHeaderLine \
   -q "$query" \
   --sort="{date: -1}" \
   --out="$NAV_DIR/$code.csv"
}

while read line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  export_watched "$line" || {
    echo "- failed to export fund $line from mongodb"
  }
done < "$DIR/watch_funds.txt"
