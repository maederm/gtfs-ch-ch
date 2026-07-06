CREATE TABLE IF NOT EXISTS gtfs.routes
(
    feed_version Date32,
    route_id         String,
    agency_id        LowCardinality(String),
    route_short_name LowCardinality(String),
    route_long_name  String,
    route_desc       LowCardinality(String),
    route_type       UInt16
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, route_id);
