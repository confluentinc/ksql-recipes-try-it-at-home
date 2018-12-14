See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/set-message-key

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._

# Setting Kafka message key using KSQL

Kafka messages are key/value pairs. The key is commonly used for partitioning and is particularly important if modeling a Kafka topic as a table in KSQL (or KTable in Kafka Streams) for query or join purposes. It is often a requirement to take data in a Kafka topic and create a derived version that includes a key based on a field within the message payload itself. This could be where the data needs a key other than that which has been set, or where the producing application hasn't set any key. An example of the latter is the JDBC connector for Kafka Connect.

# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/set-message-key
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Inspect the source `purchases` data with the `PRINT` command. Press Ctrl-C to cancel once you have a few messages shown. 

    Note that the system column `ROWKEY` representing the Kafka message's key is null: 

        ksql> PRINT 'purchases';
        Format:JSON
        {"ROWTIME":1543232251151,"ROWKEY":"null","order_id":64,"customer_name":"Denna Hoopper","date_of_birth":"1929-08-09T13:23:58Z","product":"Table Cloth 90x90 Colour","order_total_usd":"2.86","town":"Berlin","country":"Germany"}
        {"ROWTIME":1543232251621,"ROWKEY":"null","order_id":65,"customer_name":"Emera Fairham","date_of_birth":"1990-01-07T09:38:11Z","product":"Pear - Halves","order_total_usd":"0.58","town":"Newton","country":"United Kingdom"}
        {"ROWTIME":1543232252125,"ROWKEY":"null","order_id":66,"customer_name":"Stefano Gerauld","date_of_birth":"1973-02-11T05:17:18Z","product":"Soup Campbells Mexicali Tortilla","order_total_usd":"4.23","town":"Atlanta","country":"United States"}

5. The key that we want to use for the data is `order_id`. To start with, register the existing topic as a KSQL stream by providing the schema: 

        CREATE STREAM purchases \
        (order_id INT, customer_name VARCHAR, date_of_birth VARCHAR, \
        product VARCHAR, order_total_usd DOUBLE, town VARCHAR, country VARCHAR) \
        WITH (KAFKA_TOPIC='purchases', VALUE_FORMAT='JSON');
        
6. Query the stream, noting again that `ROWKEY` is null: 

        ksql> SELECT ROWKEY, ORDER_ID, PRODUCT, TOWN, COUNTRY FROM PURCHASES LIMIT 5;
        null | 975 | Wine - Red, Colio Cabernet | Saint Louis | United States
        null | 976 | Straws - Cocktale | Dallas | United States
        null | 977 | Magnotta - Bel Paese White | Jamaica | United States
        null | 978 | Cumin - Whole | Huntsville | United States
        null | 979 | Beef - Top Sirloin - Aaa | Saint Louis | United States
        Limit Reached
        Query terminated

7. Create a new KSQL stream (which is backed by a Kafka topic) with the re-keyed data using `PARTITION BY`: 

        CREATE STREAM PURCHASES_BY_ORDER_ID AS \
        SELECT * FROM PURCHASES \
        PARTITION BY ORDER_ID;

    _If you want to transform all existing messages in the topic too, run `SET 'auto.offset.reset' = 'earliest';` before executing this statement. This instructs KSQL to read from the earliest message available in the topic when populating the new stream_

6. Query the new stream, noting now that `ROWKEY` matches `ORDER_ID`: 

        ksql> SELECT ROWKEY, ORDER_ID, PRODUCT, TOWN, COUNTRY FROM PURCHASES_BY_ORDER_ID LIMIT 5;
        1248 | 1248 | Hagen Daza - Dk Choocolate | Hamburg | Germany
        1249 | 1249 | Sesame Seed | Youngstown | United States
        1250 | 1250 | Rum - White, Gg White | Stockton | United States
        1251 | 1251 | Flower - Carnations | Kansas City | United States
        1252 | 1252 | Wine - White, Pelee Island | Dallas | United States
        Limit Reached
        Query terminated
        ksql>

7. Inspect the underlying Kafka topic of the same name. Press Ctrl-C to cancel once you have a few messages shown. 

    Note that the system column `ROWKEY` representing the Kafka message's key matches the desired value, that of `ORDER_ID`: 

        ksql> PRINT 'PURCHASES_BY_ORDER_ID';
        Format:JSON
        {"ROWTIME":1543232884300,"ROWKEY":"1317","ORDER_ID":1317,"CUSTOMER_NAME":"Guillermo McNally","DATE_OF_BIRTH":"1992-06-26T10:57:35Z","PRODUCT":"Pasta - Rotini, Dry","ORDER_TOTAL_USD":4.74,"TOWN":"Garland","COUNTRY":"United States"}
        {"ROWTIME":1543232884804,"ROWKEY":"1318","ORDER_ID":1318,"CUSTOMER_NAME":"Elwira Belverstone","DATE_OF_BIRTH":"1978-01-08T06:23:08Z","PRODUCT":"Schnappes - Peach, Walkers","ORDER_TOTAL_USD":4.9,"TOWN":"Largo","COUNTRY":"United States"}
        {"ROWTIME":1543232885308,"ROWKEY":"1319","ORDER_ID":1319,"CUSTOMER_NAME":"Mollie Jaycocks","DATE_OF_BIRTH":"1985-02-13T10:03:55Z","PRODUCT":"Pork - Shoulder","ORDER_TOTAL_USD":5.41,"TOWN":"Hartford","COUNTRY":"United States"}
        ^C{"ROWTIME":1543232885815,"ROWKEY":"1320","ORDER_ID":1320,"CUSTOMER_NAME":"Barbara Caldeiro","DATE_OF_BIRTH":"1981-07-16T04:49:59Z","PRODUCT":"Cake - Dulce De Leche","ORDER_TOTAL_USD":0.19,"TOWN":"Lynchburg","COUNTRY":"United States"}
        Topic printing ceased
