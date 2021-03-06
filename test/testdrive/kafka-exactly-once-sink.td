
# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

$ set schema={
    "type": "record",
    "name": "envelope",
    "fields": [
      {
        "name": "before",
        "type": [
          {
            "name": "row",
            "type": "record",
            "fields": [
              {"name": "a", "type": "long"},
              {"name": "b", "type": "long"}
            ]
          },
          "null"
        ]
      },
      { "name": "after", "type": ["row", "null"] }
    ]
  }

$ kafka-create-topic topic=input-consistency
$ kafka-create-topic topic=input

> CREATE MATERIALIZED SOURCE input_kafka_byo
  FROM KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'testdrive-input-${testdrive.seed}'
    WITH (consistency_topic = 'testdrive-input-consistency-${testdrive.seed}')
  FORMAT AVRO USING SCHEMA '${schema}' ENVELOPE DEBEZIUM

> CREATE MATERIALIZED SOURCE input_kafka_no_byo
  FROM KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'testdrive-input-${testdrive.seed}'
  FORMAT AVRO USING SCHEMA '${schema}' ENVELOPE DEBEZIUM

> CREATE TABLE input_table (a bigint, b bigint)

> CREATE MATERIALIZED VIEW input_kafka_byo_mview AS SELECT a + 2 AS a , b + 10 AS b from input_kafka_byo;

> CREATE MATERIALIZED VIEW input_kafka_byo_mview_view AS SELECT * FROM input_kafka_byo_mview;

> CREATE VIEW input_kafka_no_byo_mview AS SELECT a + 2 AS a , b + 10 AS b from input_kafka_no_byo;

> CREATE MATERIALIZED VIEW input_kafka_no_byo_mview_view AS SELECT * FROM input_kafka_no_byo_mview;

> CREATE MATERIALIZED VIEW input_table_mview AS SELECT a + 2 AS a , b + 10 AS b from input_table;

> CREATE VIEW input_values_view AS VALUES (1), (2), (3);

> CREATE MATERIALIZED VIEW input_values_mview AS VALUES (1), (2), (3);

> CREATE MATERIALIZED VIEW input_kafka_no_byo_derived_table AS SELECT * FROM ( SELECT * FROM input_kafka_no_byo ) AS a1;

$ file-append path=static.csv
city,state,zip
Rochester,NY,14618
New York,NY,10004
"bad,place""",CA,92679

> CREATE SOURCE input_csv
  FROM FILE '${testdrive.temp-dir}/static.csv'
  FORMAT CSV WITH 3 COLUMNS

> CREATE SINK output1 FROM input_kafka_byo
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output1-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output1-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

> CREATE SINK output2 FROM input_kafka_no_byo
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output2-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output2-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

! CREATE SINK output3 FROM input_table
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output3-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output3-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
all inputs of an exactly-once Kafka sink must be sources, materialize.public.input_table is not

> CREATE SINK output4 FROM input_kafka_byo_mview
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output4-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output4-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

> CREATE SINK output4_view FROM input_kafka_byo_mview_view
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output4b-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output4b-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

> CREATE SINK output5 FROM input_kafka_no_byo_mview
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output5-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output5-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

> CREATE SINK output5_view FROM input_kafka_no_byo_mview_view
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output5b-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output5b-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

! CREATE SINK output6 FROM input_table_mview
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output6-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output6-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
all inputs of an exactly-once Kafka sink must be sources, materialize.public.input_table is not

! CREATE SINK output7 FROM input_values_view
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output7-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output7-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
all inputs of an exactly-once Kafka sink must be sources, materialize.public.input_values_view is not

! CREATE SINK output8 FROM input_values_mview
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output8-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output8-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
all inputs of an exactly-once Kafka sink must be sources, materialize.public.input_values_mview is not

> CREATE SINK output12 FROM input_kafka_no_byo_derived_table
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output12-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output12-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

> CREATE SINK output13 FROM input_csv
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'output13-view-${testdrive.seed}'
  WITH (exactly_once=true, consistency_topic='output13-view-consistency-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
