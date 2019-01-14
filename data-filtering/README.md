# Data Filtering

See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/data-filtering

## Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


## Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/data-filtering
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

6. Filter to show just those where the country is `Germany`: 

        SELECT ORDER_ID, PRODUCT, TOWN, COUNTRY FROM PURCHASES WHERE COUNTRY='Germany';

7. Create a new KSQL stream containing just German orders: 

        CREATE STREAM PUCHASES_GERMANY AS SELECT * FROM PURCHASES WHERE COUNTRY='Germany';