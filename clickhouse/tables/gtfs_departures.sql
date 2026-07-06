DROP VIEW IF EXISTS gtfs.departures_mv;

CREATE TABLE IF NOT EXISTS gtfs.departures
(
    feed_version     Date32,
    trip_id          String,
    departure_time   String,
    arrival_time     String,
    service_id       String,
    route_short_name String,
    route_type       UInt16,
    route_desc       String,
    trip_headsign    String,
    stop_id          String,
    stop_name        String,
    parent_station   String,
    platform_code    String,
    active_days      UInt8,
    start_date       Date32,
    end_date         Date32
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, parent_station, departure_time);
