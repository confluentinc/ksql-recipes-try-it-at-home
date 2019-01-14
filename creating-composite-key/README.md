# Creating a Composite Key

See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/creating-composite-key

## Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._

## Introduction

Kafka messages are key/value pairs. The key is commonly used for partitioning and is particularly important if modeling a Kafka topic as a table in KSQL (or KTable in Kafka Streams) for query or join purposes. Sometimes you might want to set, or change, the message key to a _composite_ of two or more fields in the message payload. This is usually done in the absence of a surrogate key to enable unique identification of a data point. 

In this example there is a stream of data from IoT devices, with several fields all needed to uniquely identify a given reading: 

* `site_id`
* `machine_id`
* `metric_id`

## Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/creating-composite-key
        docker-compose up -d

3. Run KSQL CLI:

        echo "Waiting for KSQL Server to start ⏳"; while [ $(curl -s -o /dev/null -w %{http_code} http://ksql-server:8088/) -eq 000 ] ; do echo -e $(date) "KSQL Server HTTP state: " $(curl -s -o /dev/null -w %{http_code} http://ksql-server:8088/) " (waiting for 200)" ; sleep 5 ; done; ksql http://ksql-server:8088

4. Inspect the source `iot_readings` data with the `PRINT` command. Press Ctrl-C to cancel once you have a few messages shown. 

    Note that the system column `ROWKEY` shows the Kafka message's key, which is currently null: 

        ksql> print 'iot_readings';
        Format:JSON
        {"ROWTIME":1543234344558,"ROWKEY":"null","site_id":1,"machine_id":42,"metric_id":3,"reading":43}
        {"ROWTIME":1543234345064,"ROWKEY":"null","site_id":1,"machine_id":44,"metric_id":4,"reading":44}
        {"ROWTIME":1543234345570,"ROWKEY":"null","site_id":2,"machine_id":44,"metric_id":4,"reading":44}
        {"ROWTIME":1543234346194,"ROWKEY":"null","site_id":1,"machine_id":42,"metric_id":1,"reading":42}


5. Register the topic as a KSQL stream by providing the schema: 

        CREATE STREAM IOT_READINGS \
        (SITE_ID INT, MACHINE_ID INT, METRIC_ID INT, READING DOUBLE) \
        WITH (KAFKA_TOPIC='iot_readings', VALUE_FORMAT='JSON');

6. Query the stream, noting again the value of `ROWKEY`:

        ksql> SELECT ROWKEY, SITE_ID, MACHINE_ID, METRIC_ID, READING FROM IOT_READINGS LIMIT 5;
        null | 2 | 44 | 4 | 44.0
        null | 1 | 42 | 1 | 42.0
        null | 1 | 42 | 2 | 41.0
        null | 1 | 42 | 3 | 43.0
        null | 1 | 44 | 4 | 44.0
        Limit Reached
        Query terminated

7. Create a new KSQL stream (which is backed by a Kafka topic) with the composite-keyed data using `PARTITION BY`: 

        CREATE STREAM IOT_READINGS_KEYED AS \
                SELECT *, \
                        CAST(SITE_ID AS STRING) + '/' + \
                        CAST(MACHINE_ID AS STRING) + '/' + \
                        CAST(METRIC_ID AS STRING) AS KEY \
                FROM IOT_READINGS \
                PARTITION BY KEY;

    _If you want to transform all existing messages in the topic too, run `SET 'auto.offset.reset' = 'earliest';` before executing this statement. This instructs KSQL to read from the earliest message available in the topic when populating the new stream_

6. Query the new stream, noting the new `ROWKEY` values: 

        ksql> SELECT ROWKEY, SITE_ID, MACHINE_ID, METRIC_ID, READING FROM IOT_READINGS_KEYED LIMIT 5;
        2/44/4 | 2 | 44 | 4 | 44.0
        1/42/1 | 1 | 42 | 1 | 42.0
        1/42/2 | 1 | 42 | 2 | 41.0
        1/42/3 | 1 | 42 | 3 | 43.0
        1/44/4 | 1 | 44 | 4 | 44.0
        Limit Reached
        Query terminated

7. Inspect the underlying Kafka topic of the same name. Press Ctrl-C to cancel once you have a few messages shown. 

    Note that the system column `ROWKEY` representing the Kafka message's key matches the desired value, a composite of `site_id`, `machine_id` and `metric_id`

        ksql> PRINT 'IOT_READINGS_KEYED';
        Format:JSON
        {"ROWTIME":1543234875101,"ROWKEY":"1/44/4","SITE_ID":1,"MACHINE_ID":44,"METRIC_ID":4,"READING":44.0,"KEY":"1/44/4"}
        {"ROWTIME":1543234875607,"ROWKEY":"2/44/4","SITE_ID":2,"MACHINE_ID":44,"METRIC_ID":4,"READING":44.0,"KEY":"2/44/4"}
        {"ROWTIME":1543234876226,"ROWKEY":"1/42/1","SITE_ID":1,"MACHINE_ID":42,"METRIC_ID":1,"READING":42.0,"KEY":"1/42/1"}
        {"ROWTIME":1543234876729,"ROWKEY":"1/42/2","SITE_ID":1,"MACHINE_ID":42,"METRIC_ID":2,"READING":41.0,"KEY":"1/42/2"}
        ^C{"ROWTIME":1543234877234,"ROWKEY":"1/42/3","SITE_ID":1,"MACHINE_ID":42,"METRIC_ID":3,"READING":43.0,"KEY":"1/42/3"}
        Topic printing ceased
