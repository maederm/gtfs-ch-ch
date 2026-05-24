CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs_rt.vehicle_positions_mv
TO gtfs_rt.vehicle_positions
AS
SELECT
    feed_version,
    feed_timestamp,
    vp_trip_id AS trip_id,
    vp_route_id AS route_id,
    vp_vehicle_id AS vehicle_id,
    vp_vehicle_label AS vehicle_label,
    vp_latitude AS latitude,
    vp_longitude AS longitude,
    vp_bearing AS bearing,
    vp_speed AS speed,
    vp_stop_id AS stop_id,
    vp_current_stop_sequence AS current_stop_sequence,
    vp_current_status AS current_status,
    vp_timestamp AS timestamp,
    vp_occupancy_status AS occupancy_status
FROM gtfs_rt.raw_feed
WHERE vp_latitude != 0 OR vp_longitude != 0;
