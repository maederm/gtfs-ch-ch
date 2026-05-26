CREATE TABLE IF NOT EXISTS gtfs_rt.trip_updates
(
    feed_version Date32,
    feed_timestamp         DateTime,
    trip_id                String,
    route_id               String,
    direction_id           UInt32,
    start_time             String,
    start_date             String,
    schedule_relationship  String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_timestamp)
ORDER BY (feed_timestamp, trip_id);
