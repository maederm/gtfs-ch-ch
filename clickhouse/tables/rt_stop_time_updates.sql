CREATE TABLE IF NOT EXISTS gtfs_rt.stop_time_updates
(
    feed_version           String,
    feed_timestamp         DateTime,
    trip_id                String,
    stop_id                String,
    stop_sequence          UInt32,
    arrival_delay          Int32,
    arrival_time           Int64,
    departure_delay        Int32,
    departure_time         Int64,
    schedule_relationship  String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_timestamp)
ORDER BY (trip_id, stop_sequence, feed_timestamp);
