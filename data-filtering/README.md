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

        cd ksql-recipes-try-it-at-home/data-filtering
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `pageviews` topic for use as a KSQL Stream called `views`: 

        CREATE STREAM views (viewtime BIGINT, userid VARCHAR, pageid VARCHAR) WITH (KAFKA_TOPIC='pageviews', VALUE_FORMAT='JSON');

5. Inspect all the messages as they arrive: 

        SELECT USERID, PAGEID FROM views;

6. Filter to show just those for `User_1`: 

        SELECT USERID, PAGEID FROM views WHERE USERID='User_1';

7. Create a new Kafka topic with only messages for `User_1`: 

        CREATE STREAM user1_views AS SELECT USERID, PAGEID FROM views WHERE USERID='User_1';
