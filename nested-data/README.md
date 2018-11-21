See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/data-filtering

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/nested-data
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `user_logons` topic for use as a KSQL Stream called `user_logons`: 

        CREATE STREAM user_logons \
        (user STRUCT<\
                first_name VARCHAR, \
                last_name VARCHAR, \
                email VARCHAR>, \
        ip_address VARCHAR, \
        logon_date VARCHAR) \
        WITH (KAFKA_TOPIC='user_logons', VALUE_FORMAT='JSON');

5. Inspect the first few messages as they arrive: 

        SELECT * FROM user_logons LIMIT 5;

2. Use the -> operator to access the nested columns.

        SELECT user->first_name AS USER_FIRST_NAME, \
                user->last_name AS USER_LAST_NAME, \
                user->email AS USER_EMAIL, \
                ip_address, \
                logon_date \
                FROM user_logons;
        
3. Persist the flattened structure as a new Kafka topic, updated continually from new messages arriving on the source topic:

        CREATE STREAM user_logons_all_cols \
                WITH (KAFKA_TOPIC='user_logons_flat') AS \
                SELECT user->first_name AS USER_FIRST_NAME, \
                        user->last_name AS USER_LAST_NAME, \
                        user->email AS USER_EMAIL, \
                        ip_address, \
                        logon_date \
                        FROM user_logons;

    Note how the target Kafka topic is explicitly set. Without `KAFKA_TOPIC` specified, the name of the stream will be used.