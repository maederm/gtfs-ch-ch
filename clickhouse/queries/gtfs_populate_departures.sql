INSERT INTO gtfs.departures
SELECT
    st.feed_version AS feed_version,
    st.trip_id AS trip_id,
    st.departure_time AS departure_time,
    st.arrival_time AS arrival_time,
    t.service_id AS service_id,
    r.route_short_name AS route_short_name,
    r.route_type AS route_type,
    r.route_desc AS route_desc,
    t.trip_headsign AS trip_headsign,
    st.stop_id AS stop_id,
    s.stop_name AS stop_name,
    s.parent_station AS parent_station,
    s.platform_code AS platform_code,
    toUInt8(c.monday + c.tuesday*2 + c.wednesday*4 + c.thursday*8 + c.friday*16 + c.saturday*32 + c.sunday*64) AS active_days,
    c.start_date AS start_date,
    c.end_date AS end_date
FROM gtfs.stop_times st
JOIN gtfs.trips t ON st.feed_version = t.feed_version AND st.trip_id = t.trip_id
JOIN gtfs.routes r ON t.feed_version = r.feed_version AND t.route_id = r.route_id
JOIN gtfs.stops s ON st.feed_version = s.feed_version AND st.stop_id = s.stop_id
LEFT JOIN gtfs.calendar c ON st.feed_version = c.feed_version AND t.service_id = c.service_id
WHERE st.feed_version = {feed_version:Date32};
