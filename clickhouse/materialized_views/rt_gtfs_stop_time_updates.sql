CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs_rt.stop_time_updates_mv
TO gtfs_rt.stop_time_updates
AS
SELECT
    feed_version,
    feed_timestamp,
    tu_trip_id AS trip_id,
    stu.stop_id AS stop_id,
    stu.stop_sequence AS stop_sequence,
    stu.arrival_delay AS arrival_delay,
    stu.arrival_time AS arrival_time,
    stu.departure_delay AS departure_delay,
    stu.departure_time AS departure_time,
    stu.schedule_relationship AS schedule_relationship
FROM gtfs_rt.raw_feed
ARRAY JOIN tu_stop_time_updates AS stu
WHERE tu_trip_id != '';
