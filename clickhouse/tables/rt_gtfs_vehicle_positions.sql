CREATE TABLE IF NOT EXISTS gtfs_rt.vehicle_positions
(
    feed_version Date32,
    feed_timestamp         DateTime,
    trip_id                String,
    route_id               String,
    vehicle_id             String,
    vehicle_label          String,
    latitude               Float32,
    longitude              Float32,
    bearing                Float32,
    speed                  Float32,
    stop_id                String,
    current_stop_sequence  UInt32,
    current_status         LowCardinality(String),
    timestamp              DateTime,
    occupancy_status       LowCardinality(String)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (vehicle_id, feed_timestamp);
