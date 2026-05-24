CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs_rt.trip_updates_mv
TO gtfs_rt.trip_updates
AS
SELECT
    feed_version,
    feed_timestamp,
    tu_trip_id AS trip_id,
    tu_route_id AS route_id,
    tu_direction_id AS direction_id,
    tu_start_time AS start_time,
    tu_start_date AS start_date,
    tu_schedule_relationship AS schedule_relationship
FROM gtfs_rt.raw_feed
WHERE tu_trip_id != '';
