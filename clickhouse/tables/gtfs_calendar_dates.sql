CREATE TABLE IF NOT EXISTS gtfs.calendar_dates
(
    feed_version Date32,
    service_id     String,
    date           Date32,
    exception_type UInt8
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, service_id, date);
