# Data Masking

See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/data-masking

## Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


## Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/data-masking
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `purchases` topic for use as a KSQL Stream called `purchases`: 

        CREATE STREAM purchases \
        (order_id INT, customer_name VARCHAR, date_of_birth VARCHAR, \
        product VARCHAR, order_total_usd VARCHAR, town VARCHAR, country VARCHAR) \
        WITH (KAFKA_TOPIC='purchases', VALUE_FORMAT='JSON');

5. Inspect the first few messages as they arrive: 

        SELECT * FROM PURCHASES LIMIT 5;

6. Create a new stream (populating a Kafka topic) that drops the PII fields: 

        CREATE STREAM PURCHASES_NO_PII AS \
        SELECT ORDER_ID, PRODUCT, ORDER_TOTAL_USD, TOWN, COUNTRY \
        FROM PURCHASES;

7. Create a new stream (populating a Kafka topic) that _masks_ the PII fields: 

        CREATE STREAM PURCHASES_MASKED_PII AS \
        SELECT  MASK(CUSTOMER_NAME) AS CUSTOMER_NAME, \
                MASK_RIGHT(DATE_OF_BIRTH,12) AS DATE_OF_BIRTH, \
                ORDER_ID, PRODUCT, ORDER_TOTAL_USD, TOWN, COUNTRY \
        FROM PURCHASES;