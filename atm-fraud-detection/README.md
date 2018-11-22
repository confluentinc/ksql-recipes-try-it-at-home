See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/atm-fraud-detection

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/atm-fraud-detection
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the source topic of ATM transactions for use as a KSQL Stream called `ATM_TXNS`: 

        CREATE STREAM ATM_TXNS (account_id VARCHAR, \
                                atm VARCHAR, \
                                location STRUCT<lon DOUBLE, \
                                                lat DOUBLE>, \
                                amount INT, \
                                timestamp VARCHAR, \
                                transaction_id VARCHAR) \
                WITH (KAFKA_TOPIC='atm_txns_gess', \
                VALUE_FORMAT='JSON', \
                TIMESTAMP='timestamp', \
                TIMESTAMP_FORMAT='yyyy-MM-dd HH:mm:ss X');

5. Create a clone of the first stream: 

        CREATE STREAM ATM_TXNS_02 \
                WITH (PARTITIONS=1) AS \
        SELECT * FROM ATM_TXNS;

6. Show a live feed of possibly fraudulent transactions:

        SELECT T1.ACCOUNT_ID AS ACCOUNT_ID, \
                TIMESTAMPTOSTRING(T1.ROWTIME, 'yyyy-MM-dd HH:mm:ss Z') AS T1_TIMESTAMP, \
               TIMESTAMPTOSTRING(T2.ROWTIME, 'yyyy-MM-dd HH:mm:ss Z') AS T2_TIMESTAMP, \
                T1.TRANSACTION_ID, T2.TRANSACTION_ID, \
                T1.AMOUNT, T2.AMOUNT, \
                T1.ATM, T2.ATM \
        FROM   ATM_TXNS T1 \
        INNER JOIN ATM_TXNS_02 T2 \
                WITHIN (0 MINUTES, 10 MINUTES) \
                ON T1.ACCOUNT_ID = T2.ACCOUNT_ID \
        WHERE   T1.TRANSACTION_ID != T2.TRANSACTION_ID \
        AND   (T1.location->lat != T2.location->lat OR \
                T1.location->lon != T2.location->lon) \
        AND   T2.ROWTIME != T1.ROWTIME;

    This implements the following criteria: 

    * Same account ID
    * Transaction takes place at a different ATM
    * Transaction takes place within 10 minutes of the previous transaction

6. For possibly fraudulent transactions, show the distance between the ATMs and the time difference between the transactions:

        SET 'auto.offset.reset' = 'earliest';

        SELECT T1.ACCOUNT_ID AS ACCOUNT_ID, \
                TIMESTAMPTOSTRING(T1.ROWTIME, 'yyyy-MM-dd HH:mm:ss Z') AS T1_TIMESTAMP, \
                TIMESTAMPTOSTRING(T2.ROWTIME, 'yyyy-MM-dd HH:mm:ss Z') AS T2_TIMESTAMP, \
                GEO_DISTANCE(T1.location->lat, T1.location->lon, \
                        T2.location->lat, T2.location->lon, 'KM') AS DISTANCE_BETWEEN_TXN_KM, \
                (CAST(T2.ROWTIME AS DOUBLE) - CAST(T1.ROWTIME AS DOUBLE)) / 1000 / 60 AS MINUTES_DIFFERENCE \
        FROM   ATM_TXNS T1 \
        INNER JOIN ATM_TXNS_02 T2 \
                WITHIN (0 MINUTES, 10 MINUTES) \
                ON T1.ACCOUNT_ID = T2.ACCOUNT_ID \
        WHERE   T1.TRANSACTION_ID != T2.TRANSACTION_ID \
        AND   (T1.location->lat != T2.location->lat OR \
                T1.location->lon != T2.location->lon) \
        AND   T2.ROWTIME != T1.ROWTIME;

7. Write a live stream of all suspected fraudulent transactions as they take place to a new Kafka topic: 

        CREATE STREAM ATM_POSSIBLE_FRAUD  \
                        WITH (PARTITIONS=1) AS \
        SELECT  T1.ROWTIME AS T1_TIMESTAMP, \
                T2.ROWTIME AS T2_TIMESTAMP, \
                GEO_DISTANCE(T1.location->lat, \
                             T1.location->lon, \
                             T2.location->lat, \
                             T2.location->lon, \
                             'KM') AS DISTANCE_BETWEEN_TXN_KM, \
                (T2.ROWTIME - T1.ROWTIME) AS MILLISECONDS_DIFFERENCE,  \
                (CAST(T2.ROWTIME AS DOUBLE) - \
                 CAST(T1.ROWTIME AS DOUBLE)) / 1000 / 60 AS MINUTES_DIFFERENCE,  \
                T1.ACCOUNT_ID AS ACCOUNT_ID, \
                T1.TRANSACTION_ID, T2.TRANSACTION_ID, \
                T1.AMOUNT, T2.AMOUNT, \
                T1.ATM, T2.ATM \
        FROM   ATM_TXNS T1 \
        INNER JOIN ATM_TXNS_02 T2 \
                WITHIN (0 MINUTES, 10 MINUTES) \
                ON T1.ACCOUNT_ID = T2.ACCOUNT_ID \
        WHERE   T1.TRANSACTION_ID != T2.TRANSACTION_ID \
        AND   (T1.location->lat != T2.location->lat OR \
                T1.location->lon != T2.location->lon) \
        AND   T2.ROWTIME != T1.ROWTIME;



# Further reading: 

* Blog: [ATM Fraud Detection with Apache Kafka and KSQL](https://www.confluent.io/blog/atm-fraud-detection-apache-kafka-ksql)
* [Full code sample with data generator, database lookups and Elasticsearch/Kibana visualisation](https://github.com/confluentinc/demo-scene/blob/master/ksql-atm-fraud-detection/ksql-atm-fraud-detection.adoc)
