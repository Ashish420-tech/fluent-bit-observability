#!/usr/bin/env bash

set -euo pipefail

SERVICE="${1:-}"
DATE="${2:-}"

if [ -z "$SERVICE" ] || [ -z "$DATE" ]; then
  echo "Usage:"
  echo "  ./download-service-log.sh <service> <YYYY-MM-DD>"
  echo
  echo "Example:"
  echo "  ./download-service-log.sh auth 2026-09-23"
  exit 1
fi

case "$SERVICE" in
  auth|catalog|parenting|vendor)
    ;;
  *)
    echo "Invalid service."
    echo "Allowed: auth catalog parenting vendor"
    exit 1
    ;;
esac

mkdir -p exports

START_SEC=$(TZ=Asia/Kolkata date -d "$DATE 00:00:00" +%s)
END_SEC=$(TZ=Asia/Kolkata date -d "$DATE +1 day 00:00:00" +%s)

START_NS="${START_SEC}000000000"
END_NS="${END_SEC}000000000"

OUTPUT="exports/${SERVICE}_${DATE}.log"

echo "Exporting:"
echo "  Service : $SERVICE"
echo "  Date    : $DATE"
echo "  Timezone: IST"
echo

curl -G -s \
  --data-urlencode "query={job=\"fluentbit\",service=\"$SERVICE\"}" \
  --data-urlencode "start=$START_NS" \
  --data-urlencode "end=$END_NS" \
  --data-urlencode "direction=forward" \
  --data-urlencode "limit=5000" \
  http://127.0.0.1:3100/loki/api/v1/query_range \
| jq -r '
    .data.result[]
    | .values[]
    | "\(.[0]) \(.[1])"
  ' > "$OUTPUT"

echo
echo "Created:"
echo "$OUTPUT"

echo
echo "Lines:"
wc -l "$OUTPUT"

echo
echo "Size:"
ls -lh "$OUTPUT"
