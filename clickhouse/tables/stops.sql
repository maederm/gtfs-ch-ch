CREATE TABLE IF NOT EXISTS gtfs.stops
(
    feed_version     String,
    stop_id          String,
    stop_name        String,
    stop_lat         Nullable(Float64),
    stop_lon         Nullable(Float64),
    location_type    Nullable(String),
    parent_station   Nullable(String),
    platform_code    Nullable(String),
    original_stop_id Nullable(String)
)
ENGINE = MergeTree()
ORDER BY (feed_version, stop_id);
