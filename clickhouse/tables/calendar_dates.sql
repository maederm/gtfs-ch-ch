CREATE TABLE IF NOT EXISTS gtfs.calendar_dates
(
    feed_version   String,
    service_id     String,
    date           Date32,
    exception_type UInt8
)
ENGINE = MergeTree()
ORDER BY (feed_version, service_id, date);
