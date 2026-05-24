#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CH_DIR="$PROJECT_DIR/clickhouse"
DATA_DIR="$PROJECT_DIR/data/gtfs_fp2026_20260520"

CH_CLIENT="${CH_CLIENT:-clickhouse-client}"

FEED_VERSION=$(awk -F',' 'NR==2 { gsub(/"/, "", $6); print $6 }' "$DATA_DIR/feed_info.txt" | tr -d '\r')
echo "=== Feed version: $FEED_VERSION ==="

echo "=== Creating database ==="
$CH_CLIENT --query="$(cat "$CH_DIR/gtfs_init.sql")"

echo "=== Creating tables ==="
for sql in "$CH_DIR/tables/gtfs_"*.sql; do
    echo "  $(basename "$sql" .sql)"
    $CH_CLIENT --queries-file="$sql"
done

echo "=== Creating materialized views ==="
for sql in "$CH_DIR/materialized_views/gtfs_"*.sql; do
    [ -f "$sql" ] || continue
    echo "  $(basename "$sql" .sql)"
    $CH_CLIENT --queries-file="$sql"
done

load_table() {
    local table=$1
    local file=$2

    echo "  Loading gtfs.$table from $file"

    local header
    header=$(head -1 "$DATA_DIR/$file" | tr -d '\r"')

    if echo "$header" | grep -q 'feed_version'; then
        tr -d '\r' < "$DATA_DIR/$file" | $CH_CLIENT \
            --date_time_input_format=best_effort \
            --input_format_csv_empty_as_default=1 \
            --query="INSERT INTO gtfs.$table FORMAT CSVWithNames"
    else
        local input_schema
        input_schema=$(echo "$header" | sed 's/,/ String, /g; s/$/ String/')

        tr -d '\r' < "$DATA_DIR/$file" | $CH_CLIENT \
            --date_time_input_format=best_effort \
            --input_format_csv_empty_as_default=1 \
            --query="INSERT INTO gtfs.$table SELECT '$FEED_VERSION' AS feed_version, * FROM input('$input_schema') FORMAT CSVWithNames"
    fi
}

echo "=== Loading data ==="
load_table agency           agency.txt
load_table feed_info        feed_info.txt
load_table calendar         calendar.txt
load_table calendar_dates   calendar_dates.txt
load_table routes           routes.txt
load_table stops            stops.txt
load_table frequencies      frequencies.txt
load_table trips            trips.txt
load_table stop_times       stop_times.txt
load_table transfers        transfers.txt

echo ""
echo "=== Row counts ==="
for sql in "$CH_DIR/tables/gtfs_"*.sql; do
    table=$(basename "$sql" .sql | sed 's/^gtfs_//')
    count=$($CH_CLIENT --query="SELECT count() FROM gtfs.$table")
    printf "  %-20s %s\n" "gtfs.$table" "$count"
done

echo ""
echo "Done."
