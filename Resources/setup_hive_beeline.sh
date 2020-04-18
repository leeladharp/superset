wget -O /opt/hadoop.tar.gz https://archive.apache.org/dist/hadoop/core/hadoop-2.5.1/hadoop-2.5.1.tar.gz
wget -O /opt/hive.tar.gz https://archive.apache.org/dist/hive/hive-1.2.2/apache-hive-1.2.2-bin.tar.gz
cd /opt/ && tar -xvzf hadoop.tar.gz && tar -xvzf hive.tar.gz
mv /opt/hadoop-2.5.1 /opt/hadoop 
mv /opt/apache-hive-1.2.2-bin /opt/hive
cp /opt/hive/lib/hive-jdbc-1.2.2.jar /opt/hive/lib/hive-jdbc.jar
