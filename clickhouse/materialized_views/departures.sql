CREATE TABLE IF NOT EXISTS gtfs.departures
(
    feed_version   String,
    trip_id        String,
    departure_time String,
    arrival_time   String,
    service_id     String,
    route_short_name String,
    route_desc     String,
    trip_headsign  String,
    stop_id        String,
    stop_name      String,
    parent_station String DEFAULT '',
    platform_code  Nullable(String)
)
ENGINE = MergeTree()
ORDER BY (feed_version, parent_station, departure_time);

CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs.departures_mv
TO gtfs.departures
AS
SELECT
    st.feed_version AS feed_version,
    st.trip_id AS trip_id,
    st.departure_time AS departure_time,
    st.arrival_time AS arrival_time,
    t.service_id AS service_id,
    r.route_short_name AS route_short_name,
    r.route_desc AS route_desc,
    t.trip_headsign AS trip_headsign,
    st.stop_id AS stop_id,
    s.stop_name AS stop_name,
    s.parent_station AS parent_station,
    s.platform_code AS platform_code
FROM gtfs.stop_times st
JOIN gtfs.trips t ON st.feed_version = t.feed_version AND st.trip_id = t.trip_id
JOIN gtfs.routes r ON t.feed_version = r.feed_version AND t.route_id = r.route_id
JOIN gtfs.stops s ON st.feed_version = s.feed_version AND st.stop_id = s.stop_id;
