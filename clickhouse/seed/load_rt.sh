#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CH_DIR="$PROJECT_DIR/clickhouse"
CH_DATA="$PROJECT_DIR/.clickhouse/servers/default/data"

CH_CLIENT="${CH_CLIENT:-clickhouse-client}"

PB_FILE="${1:-$PROJECT_DIR/data/gtfs-rt/gtfs_rt_as_proto_buf.pb}"
PB_NAME="$(basename "$PB_FILE")"
PROTO_SCHEMA="gtfs-realtime:FeedMessage"

if [ ! -f "$PB_FILE" ]; then
    echo "Error: Protobuf file not found: $PB_FILE"
    exit 1
fi

mkdir -p "$CH_DATA/user_files"
cp "$PB_FILE" "$CH_DATA/user_files/$PB_NAME"

echo "=== Creating database ==="
$CH_CLIENT --queries-file="$CH_DIR/rt_gtfs_init.sql"

echo "=== Creating tables ==="
for sql in "$CH_DIR/tables/rt_gtfs_"*.sql; do
    echo "  $(basename "$sql" .sql)"
    $CH_CLIENT --queries-file="$sql"
done

echo "=== Loading trip_updates ==="
$CH_CLIENT -q "
INSERT INTO gtfs_rt.trip_updates
SELECT
    parseDateTime32BestEffort(header.feed_version),
    header.timestamp,
    e.trip_update.trip.trip_id,
    e.trip_update.trip.route_id,
    e.trip_update.trip.direction_id,
    e.trip_update.trip.start_time,
    e.trip_update.trip.start_date,
    toString(e.trip_update.trip.schedule_relationship)
FROM file('$PB_NAME', ProtobufSingle) AS f
ARRAY JOIN f.entity AS e
WHERE e.trip_update.trip.trip_id != ''
SETTINGS format_schema='$PROTO_SCHEMA'
"

echo "=== Loading stop_time_updates ==="
$CH_CLIENT -q "
INSERT INTO gtfs_rt.stop_time_updates
SELECT
    parseDateTime32BestEffort(header.feed_version),
    header.timestamp,
    e.trip_update.trip.trip_id,
    stu.stop_id,
    stu.stop_sequence,
    stu.arrival.delay,
    stu.arrival.time,
    stu.departure.delay,
    stu.departure.time,
    toString(stu.schedule_relationship)
FROM file('$PB_NAME', ProtobufSingle) AS f
ARRAY JOIN f.entity AS e
ARRAY JOIN e.trip_update.stop_time_update AS stu
WHERE e.trip_update.trip.trip_id != ''
SETTINGS format_schema='$PROTO_SCHEMA'
"

echo "=== Loading vehicle_positions ==="
$CH_CLIENT -q "
INSERT INTO gtfs_rt.vehicle_positions
SELECT
    parseDateTime32BestEffort(header.feed_version),
    header.timestamp,
    e.vehicle.trip.trip_id,
    e.vehicle.trip.route_id,
    e.vehicle.vehicle.id,
    e.vehicle.vehicle.label,
    e.vehicle.position.latitude,
    e.vehicle.position.longitude,
    e.vehicle.position.bearing,
    e.vehicle.position.speed,
    e.vehicle.stop_id,
    e.vehicle.current_stop_sequence,
    toString(e.vehicle.current_status),
    e.vehicle.timestamp,
    toString(e.vehicle.occupancy_status)
FROM file('$PB_NAME', ProtobufSingle) AS f
ARRAY JOIN f.entity AS e
WHERE e.vehicle.position.latitude != 0 OR e.vehicle.position.longitude != 0
SETTINGS format_schema='$PROTO_SCHEMA'
"

echo "=== Loading alerts ==="
$CH_CLIENT -q "
INSERT INTO gtfs_rt.alerts
SELECT
    parseDateTime32BestEffort(header.feed_version),
    header.timestamp,
    e.id,
    toString(e.alert.cause),
    toString(e.alert.effect),
    toString(e.alert.severity_level),
    e.alert.header_text_translation[1].1,
    e.alert.description_text_translation[1].1,
    if(length(e.alert.active_period) > 0, e.alert.active_period[1].1, 0),
    if(length(e.alert.active_period) > 0, e.alert.active_period[1].2, 0),
    arrayMap(x -> x.1, e.alert.informed_entity),
    arrayMap(x -> x.2, e.alert.informed_entity),
    arrayMap(x -> x.5, e.alert.informed_entity)
FROM file('$PB_NAME', ProtobufSingle) AS f
ARRAY JOIN f.entity AS e
WHERE length(e.alert.informed_entity) > 0
SETTINGS format_schema='$PROTO_SCHEMA'
"

echo ""
echo "=== Row counts ==="
for table in trip_updates stop_time_updates vehicle_positions alerts; do
    count=$($CH_CLIENT -q "SELECT count() FROM gtfs_rt.$table")
    printf "  %-25s %s\n" "gtfs_rt.$table" "$count"
done

echo ""
echo "Done."
