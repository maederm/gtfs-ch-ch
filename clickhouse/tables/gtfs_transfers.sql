CREATE TABLE IF NOT EXISTS gtfs.transfers
(
    feed_version Date32,
    from_stop_id      String,
    to_stop_id        String,
    from_route_id     String,
    to_route_id       String,
    from_trip_id      String,
    to_trip_id        String,
    transfer_type     UInt8,
    min_transfer_time Nullable(UInt32)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, from_stop_id, to_stop_id);
