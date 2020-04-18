# Apache HIVE JDBC dialect for SQLAlchemy.
The primary purpose of this is to have a working dialect for Apache HIVE JDBC Dialect that can be used with Apache Superset.
https://superset.incubator.apache.org

## Versions  

 - Python : 3.6.x
 - Superset : 0.31.0
 - Ubuntu 16.04.06
 - Hadoop Java Client (hive-jdbc.jar and its dependencies)

## Installation

### Superset Installation

     $ pip install superset==0.31.0
     $ export SUPERSET_HOME="/etc/superset/data" (optional)
     $ superset db upgrade
     $ export FLASK_APP=superset
     $ flask fab create-admin
     $ superset init

### Installing the dialect 

1. Change directory to the root of the dialect repo

         $ cd /path/to/hive_jdbc
          
2. Run the python `setup.py` to install the dialect

          $ pip install .
          $ pip install -r requirements.txt
          $ pip install JPype1==0.6.3 --force-reinstall (the default version has a bug)

3.  copy hive2.py (DB engine spec in to  <superset installation location>/db_engine_spec/)

           $ cp hive_jdbc/patches/hive  <superset installation location>/db_engine_spec/
4. Apply the patch in JaydebeApi code (To fix bug while running multiple threads)
           
           $ patch -u <jaydebeapi installation location>/__init__.py -i  hive_jdbc/patches/jaydebe.patch

## Run Superset

        $ kinit -kt xxxxx@YYYY.keytab <PRINCIPLE>
        $ export CLASSPATH=$CLASSPATH:$(hadoop classpath):/usr/hdp/current/hadoop-client/*:/usr/hdp/current/hive-client/lib/*:/usr/hdp/current/hadoop-client/client/*
        $ export HIVE_JDBC_DRIVER_PATH=/usr/hdp/current/hive-client/lib/
        $ export HIVE_JDBC_JAR_NAME=hive-jdbc.jar

        **To start superset in dev mode**
        $ superset run -h X.X.X.X -p 9090 --with-threads --reload --debugger
        
        **To start superset in prod mode**
        $ gunicorn -w 10 -k gevent --timeout 120  -b  10.10.142.56:9090  --limit-request-line 0  --limit-request-field_size 0 superset:app

## Add a new hive database in Superset
        
To use Hive(via JDBC) with SQLAlchemy you will need to craft a connection string in the format below:

```
hive2+jdbc://zk0-xxx.xxxxxxx.onmicrosoft.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
```

## Test Run
 
    $ export CLASSPATH=$CLASSPATH:/usr/hdp/current/hadoop-client/*:/usr/hdp/current/hive-client/lib/*:/usr/hdp/current/hadoop-client/client/*
    $ export HIVE_JDBC_DRIVER_PATH=/usr/hdp/current/hive-client/lib/
    $ export HIVE_JDBC_JAR_NAME=hive-jdbc.jar
    $ python test/test_jdbc.py
 

