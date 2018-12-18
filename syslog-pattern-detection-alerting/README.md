See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/syslog-pattern-detection-alerting

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/syslog-pattern-detection-alerting
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `syslog` topic for use as a KSQL Stream called `syslog`: 

        CREATE STREAM syslog \
        (TYPE VARCHAR, HOST VARCHAR, MESSAGE VARCHAR, SEVERITY INT, TAG VARCHAR, FACILITY INT, REMOTEADDRESS VARCHAR, DATE BIGINT) \
        WITH (KAFKA_TOPIC='syslog', VALUE_FORMAT='JSON');

5. Inspect the first few messages as they arrive: 

        ksql> SELECT HOST, TAG, MESSAGE FROM SYSLOG LIMIT 20;

        rpi-02 | CRON | pam_unix(cron:session): session opened for user smmsp by (uid=0)
        rpi-02 | /USR/SBIN/CRON | (smmsp) CMD (test -x /etc/init.d/sendmail && /usr/share/sendmail/sendmail cron-msp)
        [...]

2. It's easy to filter out noise: 

        ksql> SELECT HOST, TAG, MESSAGE FROM SYSLOG \
                WHERE TAG !='CRON' \
                AND TAG !='/USR/SBIN/CRON' \
                LIMIT 20;

        rpi-02 | minissdpd | device not found for removing : uuid:RKU-42XXX-1GU4A6067130::upnp:rootdevice
        rpi-02 | minissdpd | device not found for removing : uuid:RKU-42XXX-1GU4A6067130
        [...]

3. It's also easy to filter to include just specific types of message; in this example, SSH connections

        SELECT HOST, TAG, MESSAGE FROM SYSLOG \
        WHERE TAG ='sshd' \
        LIMIT 20;

        rpi-03 | sshd | Invalid user xbmc from 186.249.209.22
        rpi-03 | sshd | input_userauth_request: invalid user xbmc [preauth]

4. Create a Kafka topic of just SSH connections, populated in real time from the source syslog topic

        CREATE STREAM SYSLOG_SSHD AS \
        SELECT * FROM SYSLOG \
        WHERE TAG ='sshd';

5. Create a Kafka topic of SSH brute-force attempts, daisy-chained from the first: 

        CREATE STREAM SYSLOG_SSHD_BRUTEFORCE_ATTACK AS \
        SELECT HOST, TAG, MESSAGE FROM SYSLOG_SSHD \
        WHERE MESSAGE LIKE 'Invalid user%';

6. Observe there are now two new topics created, each of which contain live feeds of derived syslog data based on the predicate specified: 

        ksql> LIST TOPICS;

        Kafka Topic                   | Registered | Partitions | Partition Replicas | Consumers | ConsumerGroups
        -----------------------------------------------------------------------------------------------------------
        syslog                        | true       | 1          | 1                  | 2         | 2
        SYSLOG_SSHD                   | true       | 4          | 1                  | 0         | 0
        SYSLOG_SSHD_BRUTEFORCE_ATTACK | true       | 4          | 1                  | 0         | 0


# Further reading: 

* [Kafka Connect syslog connector](https://www.confluent.io/connector/kafka-connect-syslog/)
* Blog series **We ❤️ syslogs: Real-time syslog Processing with Apache Kafka and KSQL**
  * [Part 1: Filtering](https://www.confluent.io/blog/real-time-syslog-processing-apache-kafka-ksql-part-1-filtering)
  * [Part 2: Event-Driven Alerting with Slack](https://www.confluent.io/blog/real-time-syslog-processing-with-apache-kafka-and-ksql-part-2-event-driven-alerting-with-slack/)
  * [Part 3: Enriching events with external data](https://www.confluent.io/blog/real-time-syslog-processing-apache-kafka-ksql-enriching-events-with-external-data/)
