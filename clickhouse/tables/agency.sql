CREATE TABLE IF NOT EXISTS gtfs.agency
(
    feed_version String,
    agency_id    String,
    agency_name  String,
    agency_url   String,
    agency_timezone String,
    agency_lang  String,
    agency_phone String
)
ENGINE = MergeTree()
ORDER BY (feed_version, agency_id);
