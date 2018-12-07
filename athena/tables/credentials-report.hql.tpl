CREATE EXTERNAL TABLE IF NOT EXISTS `${database-name}.${table-name}` (
  `user` string,
  arn string,
  user_creation_time string,
  password_enabled string,
  password_last_used string,
  password_last_changed string,
  password_next_rotation string,
  mfa_active boolean,
  access_key_1_active boolean,
  access_key_1_last_rotated string,
  access_key_1_last_used_date string,
  access_key_1_last_used_region string,
  access_key_1_last_used_service string,
  access_key_2_active boolean,
  access_key_2_last_rotated string,
  access_key_2_last_used_date string,
  access_key_2_last_used_region string,
  access_key_2_last_used_service string,
  cert_1_active boolean,
  cert_1_last_rotated string,
  cert_2_active boolean,
  cert_2_last_rotated string
)
PARTITIONED BY (
  year int,
  month int,
  day int,
  time int
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = ',',
  'field.delim' = ','
)
STORED AS
  INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://${credentials-report-path}'
TBLPROPERTIES (
  'has_encrypted_data'='false',
  'skip.header.line.count'='1',
  'classification'='csv',
  'columnsOrdered'='true',
  'delimiter'=',',
  'typeOfData'='file'
);
