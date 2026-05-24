CREATE TABLE IF NOT EXISTS gtfs.frequencies
(
    feed_version String,
    trip_id      String,
    start_time   String,
    end_time     String,
    headway_secs UInt32,
    exact_times  UInt8
)
ENGINE = MergeTree()
ORDER BY (feed_version, trip_id);
