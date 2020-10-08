#!/usr/bin/bash
##################################################################################################################
###Purpose: Runs cleanup serially on all nodes in the cluster (non-interactively). 
###         Logs cleanup start/end time per node, and any error or warnings to a logfile.
#Usage: ./run_cleanup.sh <nodename>
#Version: 1.2
#Changelog: 10/07/2020:Added handling for condition where cassandra/redis etc use a separate internal n/w interface
#Comments/Bugs:rsharma@cloudian.com
##################################################################################################################
clear

jps| grep -q CassandraDaemon
RET_VAL_CASS=$?
if [[ $RET_VAL_CASS -ne "0" ]]
   then
        echo "Cassandra is not running.. Exiting."
        exit 1
   else
        echo "Cassandra daemon is running.."
fi

SERVICEMAP_FILE="/opt/cloudian/conf/cloudianservicemap.json"
CASSANDRA_PID=$(jps| grep CassandraDaemon | awk '{print $1}')
CASSANDRA_PORT=9160
CASSANDRA_IP=$(ss -tlnp| grep $CASSANDRA_PID | grep $CASSANDRA_PORT  |awk '{print $4}' | cut -d ":" -f1)
CASSANDRA_INTERFACE=$(ip a | grep $CASSANDRA_IP | awk '{print $7}')

TSTAMP=$(date "+%Y.%m.%d-%H.%M.%S");
LOGFILE=/tmp/cleanup_$TSTAMP.log
echo "cassandra PID on this node:" $CASSANDRA_PID
echo "cassandra IP on this node:" $CASSANDRA_IP
echo "cassandra Interface used:" $CASSANDRA_INTERFACE

function fetch_internal_interface {

	cat $SERVICEMAP_FILE| grep  interfaces| awk '{print $4}' | grep -q $CASSANDRA_IP
	RET_VAL_C4=$?
	cat $SERVICEMAP_FILE| grep  interfaces| awk '{print $6}' | grep  -q $CASSANDRA_IP
	RET_VAL_C6=$?
	if [[ $RET_VAL_C4 -eq "0" ]]
   	   then
       		INTERFACE_CLMN=4
        elif [[ $RET_VAL_C6 -eq "0" ]]
           then
      		INTERFACE_CLMN=6
       else
           echo "Could Not Determine Interface used by Cassandra. Exiting.."
           exit 1;
        fi

# return $INTERFACE_CLMN
 echo  $INTERFACE_CLMN

}

IF_COLUMN=$(fetch_internal_interface)
echo -en  "Using column:" $IF_COLUMN
echo -en " for ethernet interface in $SERVICEMAP_FILE"
echo -e "\n"
echo "running cleanup.."
echo "Logfile: $LOGFILE"
echo -e "-=-==-=-=-=-=-=-=-=-=-\n"

for ip in `cat $SERVICEMAP_FILE | grep interfaces | awk -v N="$IF_COLUMN" '{print $N}' | sed 's/\"//g'|sed 's/\,//g'`;
    do
    	echo "Running cleanup serially, currently on:: $ip"  | tee -a  $LOGFILE
        START_TSTAMP=$(date "+%Y.%m.%d-%H.%M.%S");
        echo "Start Time:$START_TSTAMP"  | tee -a  $LOGFILE
    	/opt/cassandra/bin/nodetool -h $ip cleanup  |& tee -a  $LOGFILE
        END_TSTAMP=$(date "+%Y.%m.%d-%H.%M.%S");
        echo "End Time:$END_TSTAMP"  | tee -a  $LOGFILE
        echo -e "=====================================\n" | tee -a  $LOGFILE
    done

echo "Done. Inspect Logfile: $LOGFILE"
