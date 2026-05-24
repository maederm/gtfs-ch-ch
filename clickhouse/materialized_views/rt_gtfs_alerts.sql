CREATE MATERIALIZED VIEW IF NOT EXISTS gtfs_rt.alerts_mv
TO gtfs_rt.alerts
AS
SELECT
    feed_version,
    feed_timestamp,
    entity_id,
    alert_cause AS cause,
    alert_effect AS effect,
    alert_severity_level AS severity_level,
    alert_header_text AS header_text,
    alert_description_text AS description_text,
    alert_active_period_start AS active_period_start,
    alert_active_period_end AS active_period_end,
    alert_informed_entity_agency_ids AS informed_agency_ids,
    alert_informed_entity_route_ids AS informed_route_ids,
    alert_informed_entity_stop_ids AS informed_stop_ids
FROM gtfs_rt.raw_feed
WHERE length(alert_informed_entity_agency_ids) > 0;
