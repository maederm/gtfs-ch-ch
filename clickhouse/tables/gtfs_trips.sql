CREATE TABLE IF NOT EXISTS gtfs.trips
(
    feed_version Date32,
    route_id         LowCardinality(String),
    service_id       String,
    trip_id          String,
    trip_headsign    LowCardinality(String),
    trip_short_name  String,
    direction_id     UInt8,
    block_id         String,
    original_trip_id String,
    hints            String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, route_id, trip_id);
