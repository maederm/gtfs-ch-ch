CREATE TABLE IF NOT EXISTS gtfs.stops
(
    feed_version Date32,
    stop_id          String,
    stop_name        String,
    stop_lat         Nullable(Float64),
    stop_lon         Nullable(Float64),
    location_type    UInt8,
    parent_station   String,
    platform_code    LowCardinality(String),
    original_stop_id String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, stop_id);
