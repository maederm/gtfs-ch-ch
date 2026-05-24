CREATE TABLE IF NOT EXISTS gtfs.calendar
(
    feed_version Date32,
    service_id String,
    monday     UInt8,
    tuesday    UInt8,
    wednesday  UInt8,
    thursday   UInt8,
    friday     UInt8,
    saturday   UInt8,
    sunday     UInt8,
    start_date Date32,
    end_date   Date32
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, service_id);
