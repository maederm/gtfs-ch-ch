#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CH_DIR="$PROJECT_DIR/clickhouse"

CH_CLIENT="${CH_CLIENT:-clickhouse-client}"

source "$PROJECT_DIR/.env"

echo "=== Creating database ==="
$CH_CLIENT --queries-file="$CH_DIR/rt_gtfs_init.sql"

echo "=== Creating tables ==="
for sql in "$CH_DIR/tables/rt_gtfs_"*.sql; do
    echo "  $(basename "$sql" .sql)"
    $CH_CLIENT --queries-file="$sql"
done

echo "=== Creating named collection ==="
$CH_CLIENT -q "
CREATE NAMED COLLECTION IF NOT EXISTS gtfs_rt_api AS
  url = '$GTFSRT_URL',
  format = 'ProtobufSingle',
  \`headers.header.name\` = 'Authorization',
  \`headers.header.value\` = 'Bearer $GTFSRT_TOKEN';
"

echo "=== Creating materialized views ==="
for sql in "$CH_DIR/materialized_views/rt_gtfs_"*.sql; do
    echo "  $(basename "$sql" .sql)"
    $CH_CLIENT --queries-file="$sql"
done

echo ""
echo "=== Refreshable MV status ==="
$CH_CLIENT -q "
SELECT view, status, next_refresh_time
FROM system.view_refreshes
WHERE database = 'gtfs_rt'
FORMAT PrettyCompact
"

echo ""
echo "=== Row counts ==="
for table in raw_feed trip_updates stop_time_updates vehicle_positions alerts; do
    count=$($CH_CLIENT -q "SELECT count() FROM gtfs_rt.$table")
    printf "  %-25s %s\n" "gtfs_rt.$table" "$count"
done

echo ""
echo "Done. Refreshable MV will fetch new data every minute."
