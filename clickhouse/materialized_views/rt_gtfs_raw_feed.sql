CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs_rt.raw_feed_mv
REFRESH EVERY 1 MINUTE APPEND
TO gtfs_rt.raw_feed
AS
SELECT
    parseDateTime32BestEffort(header.feed_version) AS feed_version,
    fromUnixTimestamp(header.timestamp) AS feed_timestamp,
    e.id AS entity_id,
    e.trip_update.trip.trip_id AS tu_trip_id,
    e.trip_update.trip.route_id AS tu_route_id,
    e.trip_update.trip.direction_id AS tu_direction_id,
    e.trip_update.trip.start_time AS tu_start_time,
    e.trip_update.trip.start_date AS tu_start_date,
    toString(e.trip_update.trip.schedule_relationship) AS tu_schedule_relationship,
    arrayMap(x -> (x.stop_sequence, x.stop_id, x.arrival.delay, x.arrival.time,
                   x.departure.delay, x.departure.time,
                   toString(x.schedule_relationship)),
             e.trip_update.stop_time_update) AS tu_stop_time_updates,
    e.vehicle.trip.trip_id AS vp_trip_id,
    e.vehicle.trip.route_id AS vp_route_id,
    e.vehicle.vehicle.id AS vp_vehicle_id,
    e.vehicle.vehicle.label AS vp_vehicle_label,
    e.vehicle.position.latitude AS vp_latitude,
    e.vehicle.position.longitude AS vp_longitude,
    e.vehicle.position.bearing AS vp_bearing,
    e.vehicle.position.speed AS vp_speed,
    e.vehicle.stop_id AS vp_stop_id,
    e.vehicle.current_stop_sequence AS vp_current_stop_sequence,
    toString(e.vehicle.current_status) AS vp_current_status,
    fromUnixTimestamp(e.vehicle.timestamp) AS vp_timestamp,
    toString(e.vehicle.occupancy_status) AS vp_occupancy_status,
    toString(e.alert.cause) AS alert_cause,
    toString(e.alert.effect) AS alert_effect,
    toString(e.alert.severity_level) AS alert_severity_level,
    e.alert.header_text_translation[1].1 AS alert_header_text,
    e.alert.description_text_translation[1].1 AS alert_description_text,
    if(length(e.alert.active_period) > 0, e.alert.active_period[1].1, 0) AS alert_active_period_start,
    if(length(e.alert.active_period) > 0, e.alert.active_period[1].2, 0) AS alert_active_period_end,
    arrayMap(x -> x.1, e.alert.informed_entity) AS alert_informed_entity_agency_ids,
    arrayMap(x -> x.2, e.alert.informed_entity) AS alert_informed_entity_route_ids,
    arrayMap(x -> x.5, e.alert.informed_entity) AS alert_informed_entity_stop_ids
FROM url(gtfs_rt_api, headers('User-Agent' = 'maederm-overengineered-fahrplan')) AS f
ARRAY JOIN f.entity AS e
WHERE header.timestamp NOT IN (
    SELECT DISTINCT toUnixTimestamp(feed_timestamp) FROM gtfs_rt.raw_feed
)
SETTINGS format_schema='gtfs-realtime:FeedMessage', max_http_get_redirects=10;
