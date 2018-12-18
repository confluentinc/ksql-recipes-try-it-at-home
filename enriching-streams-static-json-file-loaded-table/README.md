See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/enriching-streams-static-json-file-loaded-table

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/enriching-streams-static-json-file-loaded-table
        docker-compose up -d

3. Ingest the account details JSON file into a Kafka topic. 

        docker-compose exec kafkacat \
        kafkacat -b kafka:29092 -P \
                 -t accounts -l /data/accounts.json \
                 -K :

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

6. Register the existing `txns` topic for use as a KSQL Stream called `txns`: 

        CREATE STREAM txns (txn_id BIGINT, userid BIGINT, recipient BIGINT, amount DOUBLE) \
        WITH (KAFKA_TOPIC = 'txns', VALUE_FORMAT = 'json');

5. Inspect the first few messages:

        SELECT * FROM txns LIMIT 5;

4. Register the existing `accounts` topic for use as a KSQL Table called `accounts`: 

        CREATE TABLE accounts (ac_key BIGINT, username VARCHAR, company VARCHAR, created_date VARCHAR) \
        WITH (KEY='ac_key', KAFKA_TOPIC = 'accounts', VALUE_FORMAT = 'json');

5. Inspect the first few messages:

        SET 'auto.offset.reset'='earliest';
        SELECT * FROM accounts LIMIT 5;

4. Join the transactions stream with the account table to create a stream of enriched transactions

        CREATE STREAM enriched_txns AS \
        SELECT TIMESTAMPTOSTRING(txns.ROWTIME, 'yyyy-MM-dd HH:mm:ss Z') AS TXN_TIMESTAMP, txn_id, userid, username, company, recipient, amount \
          FROM txns \
               INNER JOIN accounts \
               ON txns.userid = accounts.ac_key;

5. Filter the resulting transaction stream for transactions from particular company: 

        SELECT * FROM enriched_txns\
         WHERE company = 'Nitzsche Group';

    You should see the resulting transactions shown with user information, just for those in the specified company: 

        2018-12-18 15:12:13 +0000 | 445 | 11 | Farra Stearn | Nitzsche Group | 9 | 84.11
        2018-12-18 15:12:15 +0000 | 448 | 11 | Farra Stearn | Nitzsche Group | 7 | 46.24
        2018-12-18 15:12:16 +0000 | 451 | 7 | Mendel Deyenhardt | Nitzsche Group | 8 | 38.02
        […]