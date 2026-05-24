CREATE TABLE IF NOT EXISTS gtfs.agency
(
    feed_version Date32,
    agency_id    String,
    agency_name  String,
    agency_url   String,
    agency_timezone String,
    agency_lang  String,
    agency_phone String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_version)
ORDER BY (feed_version, agency_id);
