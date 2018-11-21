See https://www.confluent.io/stream-processing-cookbook/ksql-recipes/aggregating-data

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/data-aggregation
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `purchases` topic for use as a KSQL Stream called `purchases`: 

        CREATE STREAM purchases \
        (order_id INT, customer_name VARCHAR, date_of_birth VARCHAR, \
        product VARCHAR, order_total_usd DOUBLE, town VARCHAR, country VARCHAR) \
        WITH (KAFKA_TOPIC='purchases', VALUE_FORMAT='JSON');

5. Inspect the first few messages as they arrive: 

        SELECT * FROM PURCHASES LIMIT 5;

6. Aggregate the order values (`ORDER_TOTAL_USD`) by Country: 

        SELECT COUNTRY, \
               COUNT(*) AS ORDER_COUNT, \
               SUM(ORDER_TOTAL_USD) AS ORDER_TOTAL_USD \
          FROM PURCHASES \
                WINDOW TUMBLING (SIZE 5 MINUTES) \
          GROUP BY COUNTRY;

    Note that as each new event arrives it will trigger an update of the aggregate, which will be re-emitted: 

        United States | 591.3700000000001 | 124
        Germany | 81.15 | 15
        United States | 609.0200000000001 | 127
        United Kingdom | 52.870000000000005 | 11
        United States | 616.8600000000001 | 130
        United States | 638.9900000000002 | 134    

7. The message key includes the timestamp window, as can be seen if we persist the results to a KSQL Table: 

        CREATE TABLE ORDERS_BY_COUNTRY_BY_5_MINS AS \
        SELECT COUNTRY, \
               COUNT(*) AS ORDER_COUNT, \
               SUM(ORDER_TOTAL_USD) AS ORDER_TOTAL_USD \
          FROM PURCHASES \
                WINDOW TUMBLING (SIZE 5 MINUTES) \
          GROUP BY COUNTRY;

        ksql> SELECT ROWKEY, COUNTRY, ORDER_COUNT, ORDER_TOTAL_USD FROM ORDERS_BY_COUNTRY_BY_5_MINS;

        United States : Window{start=1542800400000 end=-} | United States | 193 | 960.8500000000001
        Germany : Window{start=1542800400000 end=-} | Germany | 24 | 120.51000000000002
        United Kingdom : Window{start=1542800400000 end=-} | United Kingdom | 16 | 64.64