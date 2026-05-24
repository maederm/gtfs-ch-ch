CREATE TABLE IF NOT EXISTS gtfs.transfers
(
    feed_version      String,
    from_stop_id      String,
    to_stop_id        String,
    from_route_id     Nullable(String),
    to_route_id       Nullable(String),
    from_trip_id      Nullable(String),
    to_trip_id        Nullable(String),
    transfer_type     UInt8,
    min_transfer_time Nullable(UInt32)
)
ENGINE = MergeTree()
ORDER BY (feed_version, from_stop_id, to_stop_id);
