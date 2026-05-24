CREATE TABLE IF NOT EXISTS gtfs.feed_info
(
    feed_version        String,
    feed_publisher_name String,
    feed_publisher_url  String,
    feed_lang           String,
    feed_start_date     Date32,
    feed_end_date       Date32
)
ENGINE = MergeTree()
ORDER BY (feed_version, feed_publisher_name);
