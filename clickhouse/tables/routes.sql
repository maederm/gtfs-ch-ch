CREATE TABLE IF NOT EXISTS gtfs.routes
(
    feed_version     String,
    route_id         String,
    agency_id        String,
    route_short_name String,
    route_long_name  String,
    route_desc       String,
    route_type       UInt16
)
ENGINE = MergeTree()
ORDER BY (feed_version, route_id);
