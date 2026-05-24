CREATE TABLE IF NOT EXISTS gtfs.trips
(
    feed_version Date32,
    route_id         String,
    service_id       String,
    trip_id          String,
    trip_headsign    String,
    trip_short_name  String,
    direction_id     UInt8,
    block_id         Nullable(String),
    original_trip_id Nullable(String),
    hints            Nullable(String)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, route_id, trip_id);
