CREATE TABLE IF NOT EXISTS gtfs.calendar_by_day
(
    feed_version Date32,
    service_id   String,
    day_of_week  UInt8,
    start_date   Date32,
    end_date     Date32
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, service_id, day_of_week);

CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs.calendar_by_day_mv
TO gtfs.calendar_by_day
AS
SELECT
    feed_version,
    service_id,
    day_of_week,
    start_date,
    end_date
FROM gtfs.calendar
ARRAY JOIN [monday, tuesday, wednesday, thursday, friday, saturday, sunday] AS active,
           [1, 2, 3, 4, 5, 6, 7] AS day_of_week
WHERE active = 1;
