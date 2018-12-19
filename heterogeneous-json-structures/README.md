See http://www.confluent.io/stream-processing-cookbook/ksql-recipes/heterogeneous-json-structures/

# Pre-reqs: 

* Docker
* If running on Mac/Windows, at least 4GB allocated to Docker: 

      docker system info | grep Memory 

    _Should return a value greater than 8GB - if not, the Kafka stack will probably not work._

# Intro

Sometimes the messages on a Kafka topic will not have the same structure. For example: 

* a field is not present in each message
* there are messages of multiple types in the topic, for example: 

        { "Header": { "RecType": "RecA" }, "RAFld1": { "someFld": "some data", "someOtherField": 1.001 }, "RAFld2": { "aFld": "data", "anotherFld": 98.6 } }
        { "Header": { "RecType": "RecB" }, "RBFld1": { "randomFld": "random data", "randomOtherField": 1.001 } }

When defining a stream in KSQL against a topic with JSON data, there are some useful techniques to be aware of: 

* You can declare a schema for fields that are not present in every message. If a field is not present then a `null` is returned. 
* Use `STRUCT` for nested fields if you want to declare the schema for the contents too
* You can use `VARCHAR` against the parent element of a nested field, and then `EXTRACTJSONFIELDFIELD` function to access nested fields at execution time


# Try it at home!

1. Clone this repository

        git clone https://github.com/confluentinc/ksql-recipes-try-it-at-home.git

2. Launch: 

        cd ksql-recipes-try-it-at-home/heterogeneous-json-structures/
        docker-compose up -d

3. Run KSQL CLI:

        docker-compose exec ksql-cli ksql http://ksql-server:8088

4. Inspect the raw data: 

        ksql> PRINT 'source_data' FROM BEGINNING;
        Format:JSON
        {"ROWTIME":1545239521600,"ROWKEY":"null","Header":{"RecType":"RecA"},"RAFld1":{"someFld":"some data","someOtherField":1.001},"RAFld2":{"aFld":"data","anotherFld":98.6}}
        {"ROWTIME":1545239526600,"ROWKEY":"null","Header":{"RecType":"RecB"},"RBFld1":{"randomFld":"random data","randomOtherField":1.001}}

6. Register the `source_data` topic for use as a KSQL Stream called `my_stream`: 

        CREATE STREAM my_stream (Header VARCHAR, \
                                 RAFld1 VARCHAR, \
                                 RAFld2 VARCHAR, \
                                 RBFld1 VARCHAR) \
        WITH (KAFKA_TOPIC='source_data', VALUE_FORMAT='JSON');

5. Inspect the messages. Note that in the second message (which is record type "B") there is no value for 'RAFld1' and so a `null` is shown: 

        ksql> SELECT Header, RAFld1 FROM my_stream LIMIT 2;
        {"RecType":"RecA"} | {"someOtherField":1.001,"someFld":"some data"}
        {"RecType":"RecB"} | null

4. Populate a new Kafka topic with just record type "A" values, using `EXTRACTFROMJSON` to filter record types on the Header value, and to extract named fields from the payload: 

        CREATE STREAM recA_data WITH (VALUE_FORMAT='AVRO') AS \
        SELECT EXTRACTJSONFIELD(RAFld1,'$.someOtherField') AS someOtherField, \
                EXTRACTJSONFIELD(RAFld1,'$.someFld')        AS someFld, \
                EXTRACTJSONFIELD(RAFld2,'$.aFld')           AS aFld, \
                EXTRACTJSONFIELD(RAFld2,'$.anotherFld')     AS anotherFld \
                FROM my_stream \
        WHERE EXTRACTJSONFIELD(Header,'$.RecType') = 'RecA';

    Note that the serialisation is being switched to Avro so that the schema is available automatically to any consumer, without having to manually declare it. 
5. Observe the new stream has a schema and is populated continually with messages as they arrive in the original `source_data` topic: 

        ksql> DESCRIBE recA_data;

        Name                 : RECA_DATA
        Field          | Type
        --------------------------------------------
        ROWTIME        | BIGINT           (system)
        ROWKEY         | VARCHAR(STRING)  (system)
        SOMEOTHERFIELD | VARCHAR(STRING)
        SOMEFLD        | VARCHAR(STRING)
        AFLD           | VARCHAR(STRING)
        ANOTHERFLD     | VARCHAR(STRING)
        --------------------------------------------
        For runtime statistics and query details run: DESCRIBE EXTENDED <Stream,Table>;

        ksql> SELECT * FROM recA_data;
        1545240188787 | null | 1.001 | some data | data | 98.6