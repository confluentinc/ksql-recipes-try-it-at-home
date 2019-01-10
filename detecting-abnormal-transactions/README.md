See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/detecting-abnormal-transactions

# Introduction

A common pattern for fraudsters is to disguise transactions within an account that references a set of popular organizations, the idea being that that chances of them being recognized is very low. For example, transactions labeled Verizon, Citibank, USPS, etc., are likely to look similar and blend in.

There will normally be a group of such transactions that occur within a 24-hour period, where they are all new—that is, they have not been seen within the last 30 days. When it comes to fraud detection, financial institutions will categorize this behavior as unusual and alert their fraud team to investigate immediately to block the offending card.


# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/detecting-abnormal-transactions
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Register the existing `suspicious-accounts` topic for use as a KSQL Table called `SUSPICIOUS_NAMES`:

        CREATE TABLE SUSPICIOUS_NAMES (CREATED_DATE VARCHAR, \
                                                COMPANY_NAME VARCHAR, \
                                                COMPANY_ID INT) \
                                        WITH (KEY='COMPANY_NAME', \
                                                KAFKA_TOPIC = 'suspicious-accounts', \
                                                VALUE_FORMAT = 'JSON');

5. Register the existing `txns-1` topic for use as a KSQL Stream called `TXNS`. The transaction information includes the identifier, the user sending the money, and the name of the recipient. 

        CREATE STREAM TXNS (TXN_ID BIGINT, \
                            USERNAME VARCHAR, \
                            RECIPIENT VARCHAR, \
                            AMOUNT DOUBLE) \
                      WITH (KAFKA_TOPIC = 'txns-1', \
                            VALUE_FORMAT = 'JSON');

6. Inspect the data: 

        ksql> SET 'auto.offset.reset'='earliest';

        ksql> SELECT * FROM SUSPICIOUS_NAMES LIMIT 3;
        1547119341566 | verizon | 2017-09-15 09:08:38 | verizon | 1
        1547119341566 | alcatel | 2017-09-16 09:08:38 | alcatel | 2
        1547119341566 | best buy | 2017-09-17 09:08:38 | best buy | 3
        Limit Reached
        Query terminated

        ksql> SELECT * FROM TXNS LIMIT 3;
        1547119343620 | 9900 | 9900 | alan jones | verizon | 22.0
        1547119350852 | 12 | 12 | bruce atkins | joe blogs | 7.0
        1547119350868 | 13 | 13 | mary simpson | joe blogs | 70.0
        Limit Reached
        Query terminated        

7. Using the list of suspicious destination names for transactions, create a new stream of events containing transactions that were sent to an account name contained in the `SUSPICIOUS_NAMES` list

        CREATE STREAM SUSPICIOUS_TXNS AS \
        SELECT T.TXN_ID, T.USERNAME, T.RECIPIENT, T.AMOUNT \
          FROM TXNS T \
               INNER JOIN \
               SUSPICIOUS_NAMES S \
               ON T.RECIPIENT = S.COMPANY_NAME;

    Observe that a new Kafka topic has been created, and is used to persist the results of this new stream: 

        ksql> LIST TOPICS;

        Kafka Topic         | Registered | Partitions | Partition Replicas | Consumers | ConsumerGroups
        -------------------------------------------------------------------------------------------------
        SUSPICIOUS_TXNS     | true       | 4          | 1                  | 0         | 0
        …

8. Inspect the new stream, and note that all the transactions are to one of the companies present in the `SUSPICIOIUS_ACCOUNTS` table: 

        ksql> SELECT TXN_ID, USERNAME, RECIPIENT, AMOUNT FROM SUSPICIOUS_TXNS LIMIT 5;
        9900 | alan jones | verizon | 22.0
        9903 | alan jones | verizon | 61.0
        9901 | alan jones | alcatel | 83.0
        9902 | alan jones | best buy | 46.0
        9904 | alan jones | alcatel | 59.0
        Limit Reached
        Query terminated

9. Use a tumbling window create a table of accounts (`USERNAME`) against which there are more than three suspicious transactions within a 24 hour window: 

        CREATE TABLE ACCOUNTS_TO_MONITOR AS \
        SELECT TIMESTAMPTOSTRING(WindowStart(), 'yyyy-MM-dd HH:mm:ss Z') AS WINDOW_START, \
                USERNAME, \
                COUNT(*) AS TXN_COUNT \
        FROM SUSPICIOUS_TXNS \
                WINDOW TUMBLING (SIZE 24 HOURS) \
        GROUP BY USERNAME \
        HAVING COUNT(*) > 3;

10. Observe that a new Kafka topic is created: 

        ksql> LIST TOPICS;

        Kafka Topic          | Registered | Partitions | Partition Replicas | Consumers | ConsumerGroups
        --------------------------------------------------------------------------------------------------
        ACCOUNTS_TO_MONITOR  | true       | 4          | 1                  | 0         | 0
        …

    The KSQL table (and thus Kafka topic) contains a list of accounts against which more than 3 suspicious transactions have taken place in a 24 hour window. The window start time is included in the Kafka message: 

        ksql> SELECT WINDOW_START, USERNAME, TXN_COUNT FROM ACCOUNTS_TO_MONITOR;
        2019-01-10 00:00:00 +0000 | alan jones | 6

    This Kafka topic can be used to drive monitoring and alerting applications that could take action such as placing a hold on the account, notifying the card holder, etc. 