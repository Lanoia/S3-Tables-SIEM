-- one row per log event
-- partitioned by day and source
CREATE TABLE events (
  event_id        string,
  event_time      timestamp,  -- UTC
  source          string,
  category        string,
  event_type      string,
  action          string,
  outcome         string,
  severity        string,
  user_name       string,
  src_ip          string,
  dst_ip          string,
  dst_port        int,
  host            string,
  raw_object_key  string,     -- S3 key of the original file in the raw bucket
  raw_version_id  string,     -- S3 version ID of that file
  raw             string      -- original log line
)
PARTITIONED BY (day(event_time), source)
TBLPROPERTIES ('table_type' = 'iceberg')