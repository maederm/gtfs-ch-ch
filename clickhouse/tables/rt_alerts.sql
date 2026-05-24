CREATE TABLE IF NOT EXISTS gtfs_rt.alerts
(
    feed_version           String,
    feed_timestamp         DateTime,
    entity_id              String,
    cause                  String,
    effect                 String,
    severity_level         String,
    header_text            String,
    description_text       String,
    active_period_start    Nullable(DateTime),
    active_period_end      Nullable(DateTime),
    informed_agency_ids    Array(String),
    informed_route_ids     Array(String),
    informed_stop_ids      Array(String)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_timestamp)
ORDER BY (entity_id, feed_timestamp);
