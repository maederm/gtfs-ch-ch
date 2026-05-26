CREATE VIEW IF NOT EXISTS gtfs.departures_rt_view AS
WITH latest_rt AS (
    SELECT max(feed_timestamp) AS ts FROM gtfs_rt.trip_updates
)
SELECT
    departure_time,
    route_short_name,
    route_desc,
    trip_headsign,
    platform_code,
    service_id,
    schedule_relationship,
    departure_delay
FROM (
    SELECT
        d.departure_time AS departure_time,
        d.route_short_name AS route_short_name,
        d.route_desc AS route_desc,
        d.trip_headsign AS trip_headsign,
        d.platform_code AS platform_code,
        d.service_id AS service_id,
        tu.schedule_relationship AS schedule_relationship,
        stu.departure_delay AS departure_delay
    FROM (
        SELECT feed_version, trip_id, stop_id, departure_time,
               route_short_name, route_desc, trip_headsign, platform_code, service_id
        FROM gtfs.departures
        WHERE parent_station = {parent_station:String}
          AND feed_version = (SELECT max(feed_version) FROM gtfs.feed_info)
          AND bitTest(active_days, toDayOfWeek({date:Date32}) - 1)
          AND start_date <= {date:Date32}
          AND end_date >= {date:Date32}
        ORDER BY departure_time ASC
    ) d
    LEFT JOIN gtfs_rt.trip_updates tu ON d.trip_id = tu.trip_id AND tu.feed_timestamp = (SELECT ts FROM latest_rt)
    LEFT JOIN gtfs_rt.stop_time_updates stu ON d.trip_id = stu.trip_id AND d.stop_id = stu.stop_id AND stu.feed_timestamp = (SELECT ts FROM latest_rt)
)
WHERE service_id NOT IN (
    SELECT service_id FROM gtfs.calendar_dates
    WHERE feed_version = (SELECT max(feed_version) FROM gtfs.feed_info)
      AND date = {date:Date32} AND exception_type = 2
);
