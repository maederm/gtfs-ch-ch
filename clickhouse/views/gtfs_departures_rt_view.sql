CREATE VIEW IF NOT EXISTS gtfs.departures_rt_view AS
WITH removed_services AS (
    SELECT service_id
    FROM gtfs.calendar_dates
    WHERE feed_version = (SELECT max(feed_version) FROM gtfs.feed_info)
      AND date = {date:Date32}
      AND exception_type = 2
),
added_services AS (
    SELECT service_id
    FROM gtfs.calendar_dates
    WHERE feed_version = (SELECT max(feed_version) FROM gtfs.feed_info)
      AND date = {date:Date32}
      AND exception_type = 1
),
latest_rt AS (
    SELECT max(feed_timestamp) AS ts FROM gtfs_rt.trip_updates
)
SELECT
    d.*,
    tu.schedule_relationship AS schedule_relationship,
    if(stu.stop_id != '', stu.departure_delay, NULL) AS departure_delay,
    if(stu.stop_id != '', stu.arrival_delay, NULL) AS arrival_delay
FROM gtfs.departures d
LEFT JOIN gtfs_rt.trip_updates tu ON d.feed_version = tu.feed_version AND d.trip_id = tu.trip_id AND tu.feed_timestamp = (SELECT ts FROM latest_rt)
LEFT JOIN gtfs_rt.stop_time_updates stu ON d.feed_version = stu.feed_version AND d.trip_id = stu.trip_id AND d.stop_id = stu.stop_id AND stu.feed_timestamp = (SELECT ts FROM latest_rt)
WHERE d.feed_version = (SELECT max(feed_version) FROM gtfs.feed_info)
  AND (
    bitTest(d.active_days, toDayOfWeek({date:Date32}) - 1)
    AND d.start_date <= {date:Date32}
    AND d.end_date >= {date:Date32}
    AND d.service_id NOT IN (SELECT service_id FROM removed_services)
    OR d.service_id IN (SELECT service_id FROM added_services)
  );
