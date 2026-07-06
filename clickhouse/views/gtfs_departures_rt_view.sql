CREATE OR REPLACE VIEW gtfs.departures_rt_view AS
WITH active_feed AS (
    SELECT least(
        (SELECT max(feed_version) FROM gtfs.feed_info),
        (SELECT max(feed_version) FROM gtfs_rt.trip_updates)
    ) AS feed_version
),
latest_rt AS (
    SELECT max(feed_timestamp) AS ts FROM gtfs_rt.trip_updates
    WHERE feed_version = (SELECT feed_version FROM active_feed)
)
SELECT
    d.departure_time AS departure_time,
    {date:Date32} + toTime(d.departure_time) AS scheduled_departure_time,
    d.route_short_name AS route_short_name,
    d.route_type AS route_type,
    d.route_desc AS route_desc,
    d.trip_headsign AS trip_headsign,
    d.platform_code AS platform_code,
    tu.schedule_relationship AS schedule_relationship,
    stu.departure_delay AS departure_delay,
    addSeconds(
        {date:Date32} + toTime(d.departure_time),
        ifNull(stu.departure_delay, 0)
    ) AS expected_departure_time
FROM (
    SELECT feed_version, trip_id, stop_id, departure_time,
           route_short_name, route_type, route_desc, trip_headsign, platform_code, service_id
    FROM gtfs.departures
    WHERE parent_station = {parent_station:String}
      AND feed_version = (SELECT feed_version FROM active_feed)
      AND bitTest(active_days, toDayOfWeek({date:Date32}) - 1)
      AND start_date <= {date:Date32}
      AND end_date >= {date:Date32}
      AND service_id NOT IN (
        SELECT service_id FROM gtfs.calendar_dates
        WHERE feed_version = (SELECT feed_version FROM active_feed)
          AND date = {date:Date32} AND exception_type = 2
          AND service_id IN (
            SELECT DISTINCT service_id FROM gtfs.departures
            WHERE parent_station = {parent_station:String}
              AND feed_version = (SELECT feed_version FROM active_feed)
          )
      )
    ORDER BY departure_time ASC
) d
LEFT JOIN gtfs_rt.trip_updates tu ON d.trip_id = tu.trip_id AND d.feed_version = tu.feed_version AND tu.feed_timestamp = (SELECT ts FROM latest_rt)
LEFT JOIN gtfs_rt.stop_time_updates stu ON d.trip_id = stu.trip_id AND d.stop_id = stu.stop_id AND d.feed_version = stu.feed_version AND stu.feed_timestamp = (SELECT ts FROM latest_rt)
ORDER BY d.departure_time ASC;
