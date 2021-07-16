-- Lookup Source: Sync Mode
-- kafka source
CREATE TABLE user_log (
  user_id STRING
  ,item_id STRING
  ,category_id STRING
  ,behavior STRING
  ,ts TIMESTAMP(3)
  ,process_time as proctime()
  , WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka'
  ,'topic' = 'user_behavior'
  ,'properties.bootstrap.servers' = 'localhost:9092'
  ,'properties.group.id' = 'user_log'
  ,'scan.startup.mode' = 'group-offsets'
  ,'format' = 'json'
);

drop table if exists hbase_behavior_conf ;
CREATE TEMPORARY TABLE hbase_behavior_conf (
   rowkey STRING
  ,cf ROW(`c` STRING, v STRING)
) WITH (
   'connector' = 'hbase-2.2'
   ,'zookeeper.quorum' = '10.201.1.129:2181,10.201.1.130:2181,10.201.1.131:2181'
   ,'table-name' = 'test'
   ,'lookup.cache.max-rows' = '10000'
   ,'lookup.cache.ttl' = '10 minute' -- ttl time 超过这么长时间无数据才行
   ,'lookup.async' = 'true'
);

---sinkTable
CREATE TABLE kakfa_join_mysql_demo (
  user_id STRING
  ,item_id STRING
  ,category_id STRING
  ,behavior STRING
  ,behavior_map STRING
  ,ts TIMESTAMP(3)
--   ,primary key (user_id) not enforced
) WITH (
   'connector' = 'kafka'
  ,'topic' = 'user_behavior_1'
  ,'properties.bootstrap.servers' = 'localhost:9092'
  ,'properties.group.id' = 'user_log'
  ,'scan.startup.mode' = 'group-offsets'
  ,'format' = 'json'
);

INSERT INTO kakfa_join_mysql_demo(user_id, item_id, category_id, behavior, behavior_map, ts)
SELECT a.user_id, a.item_id, a.category_id, a.behavior, c.cf.v, a.ts
FROM user_log a
  left join hbase_behavior_conf FOR SYSTEM_TIME AS OF a.process_time AS c
  ON a.behavior = rowkey
where a.behavior is not null;