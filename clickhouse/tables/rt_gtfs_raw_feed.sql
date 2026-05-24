CREATE TABLE IF NOT EXISTS gtfs_rt.raw_feed
(
    feed_version    Date32,
    feed_timestamp  DateTime,
    entity_id       String,
    tu_trip_id                 String,
    tu_route_id                String,
    tu_direction_id            UInt32,
    tu_start_time              String,
    tu_start_date              String,
    tu_schedule_relationship   String,
    tu_stop_time_updates       Array(Tuple(
        stop_sequence          UInt32,
        stop_id                String,
        arrival_delay          Int32,
        arrival_time           Int64,
        departure_delay        Int32,
        departure_time         Int64,
        schedule_relationship  String
    )),
    vp_trip_id                 String,
    vp_route_id                String,
    vp_vehicle_id              String,
    vp_vehicle_label           String,
    vp_latitude                Float32,
    vp_longitude               Float32,
    vp_bearing                 Float32,
    vp_speed                   Float32,
    vp_stop_id                 String,
    vp_current_stop_sequence   UInt32,
    vp_current_status          String,
    vp_timestamp               DateTime,
    vp_occupancy_status        String,
    alert_cause                String,
    alert_effect               String,
    alert_severity_level       String,
    alert_header_text          String,
    alert_description_text     String,
    alert_active_period_start  UInt64,
    alert_active_period_end    UInt64,
    alert_informed_entity_agency_ids  Array(String),
    alert_informed_entity_route_ids   Array(String),
    alert_informed_entity_stop_ids    Array(String)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(feed_timestamp)
ORDER BY (feed_timestamp, entity_id);
