CREATE TABLE IF NOT EXISTS gtfs.frequencies
(
    feed_version Date32,
    trip_id      String,
    start_time   String,
    end_time     String,
    headway_secs UInt32,
    exact_times  UInt8
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, trip_id);
