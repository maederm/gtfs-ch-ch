CREATE TABLE IF NOT EXISTS gtfs_rt.alerts
(
    feed_version Date32,
    feed_timestamp         DateTime,
    entity_id              String,
    cause                  LowCardinality(String),
    effect                 LowCardinality(String),
    severity_level         LowCardinality(String),
    header_text            String,
    description_text       String,
    active_period_start    Nullable(DateTime),
    active_period_end      Nullable(DateTime),
    informed_agency_ids    Array(String),
    informed_route_ids     Array(String),
    informed_stop_ids      Array(String)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (entity_id, feed_timestamp);
