-- mysql cdc to print
-- creates a mysql table source
CREATE TABLE t_user_behavior (
  id bigint
  ,user_id bigint
  ,item_id bigint
  ,category_id bigint
  ,behavior varchar
  ,ts timestamp(3)
  ,proc_time as PROCTIME()
  ,PRIMARY KEY (id) NOT ENFORCED
) WITH (
 'connector' = 'mysql-cdc'
 ,'hostname' = 'localhost'
 ,'port' = '3306'
 ,'username' = 'root'
 ,'password' = '123456'
 ,'database-name' = 'venn'
 ,'table-name' = 'user_behavior'
 ,'server-id' = '12345678'
 ,'scan.startup.mode' = 'initial'
--  ,'scan.startup.mode' = 'specific-offset'
--  ,'scan.startup.specific-offset.file' = 'mysql-bin.000001'
--  ,'scan.startup.specific-offset.pos' = '1'
);

-- kafka sink
drop table if exists t_user_behavior_sink;
CREATE TABLE t_user_behavior_sink (
  id bigint
  ,user_id bigint
  ,item_id bigint
  ,category_id bigint
  ,behavior varchar
  ,ts timestamp(3)
  ,PRIMARY KEY (id) NOT ENFORCED
) WITH (
   'connector' = 'upsert-kafka'
  ,'topic' = 'user_behavior_sink'
  ,'properties.bootstrap.servers' = 'localhost:9092'
  ,'properties.group.id' = 'user_log'
  ,'key.format' = 'json'
  ,'key.json.ignore-parse-errors' = 'true'
  ,'value.format' = 'json'
  ,'value.json.fail-on-missing-field' = 'false'
  ,'value.fields-include' = 'ALL'
);

insert into t_user_behavior_sink
select id, user_id, item_id, category_id, behavior, ts
from t_user_behavior;


