See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/geoip

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

_Docker will automagically download the required GeoIP database file from https://geolite.maxmind.com, and therefore your host machine will need to have internet connectivity._

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/geoip
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `clickstream` topic for use as a KSQL Stream called `clickstream`: 

        CREATE STREAM clicks (ip VARCHAR, url VARCHAR, response INT) \
        WITH (KAFKA_TOPIC = 'clicks', VALUE_FORMAT = 'DELIMITED');

5. Inspect the first few messages as they arrive: 

        SELECT IP, REQUEST, STATUS FROM clickstream LIMIT 5;

6. Use the `GetCityForIP` function to derive the location from the IP: 

        SELECT IP, GETCITYFORIP(IP), URL, RESPONSE FROM clicks LIMIT 5;

