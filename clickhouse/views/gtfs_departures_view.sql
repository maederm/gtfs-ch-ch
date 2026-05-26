CREATE VIEW IF NOT EXISTS gtfs.departures_view AS
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
)
SELECT *
FROM gtfs.departures
WHERE feed_version = (SELECT max(feed_version) FROM gtfs.feed_info)
  AND (
    bitTest(active_days, toDayOfWeek({date:Date32}) - 1)
    AND start_date <= {date:Date32}
    AND end_date >= {date:Date32}
    AND service_id NOT IN (SELECT service_id FROM removed_services)
    OR service_id IN (SELECT service_id FROM added_services)
  );
