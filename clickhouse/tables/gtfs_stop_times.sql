CREATE TABLE IF NOT EXISTS gtfs.stop_times
(
    feed_version Date32,
    trip_id        String,
    arrival_time   String,
    departure_time String,
    stop_id        String,
    stop_sequence  UInt32,
    pickup_type    UInt8,
    drop_off_type  UInt8
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, trip_id, stop_sequence);
