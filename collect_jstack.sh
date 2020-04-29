#!/usr/bin/bash -x
#################################
##Purpose: The script collects jstack of top java threads consumed by cassandra, storageserver and s3 
##         on a single node
#################################

##Identify PID for c*, HS, and s3

cassandra_PID=`jps | grep CassandraDaemon | awk '{print $1}'`
storageserver_PID=`jps | grep StorageServer | awk '{print $1}'`
s3_PID=`jps | grep S3Server | awk '{print $1}'`
ts=$(date "+%Y.%m.%d-%H.%M.%S")
node=`hostname`
LOG_DIR="/tmp"

##Collect 5 samples of top threads 
echo "collecting 5 samples of top threads for Cassandra PID: $cassandra_PID .."
 top -b -n 5 -H -p $cassandra_PID > $LOG_DIR/top-threads_cassandra_"$node"_$ts.out
echo "collecting 5 samples of top threads for StorageServer PID: $storageserver_PID .."
 top -b -n 5 -H -p $storageserver_PID > $LOG_DIR/top-threads_hs_"$node"_$ts.out
echo "collecting 5 samples of top threads for S3 PID: $s3_PID .."
 top -b -n 5 -H -p $s3_PID > $LOG_DIR/top-threads_s3_"$node"_$ts.out

##collect jstack
echo "collecting jstack for Cassandra PID: $cassandra_PID .."
sudo -u cloudian jstack -J-d64 $cassandra_PID  > $LOG_DIR/jstack-cassandra_"$node"_$ts.out
sudo -u cloudian jstack -J-d64 $storageserver_PID  > $LOG_DIR/jstack-hs_"$node"_$ts.out
sudo -u cloudian jstack -J-d64 $s3_PID > $LOG_DIR/jstack-s3_"$node"_$ts.out

##6 Files are generated in $LOG_DIR
echo "Files Generated:"
ls $LOG_DIR/top-threads*.out
ls $LOG_DIR/jstack*.out
