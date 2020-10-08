#!/usr/bin/bash
##################################################################################################################
##Purpose: Captures Token Mapping from all nodes in the cluster (non-interactively)
##based on the output of `hsstool ring`
##Usage: ./collect_token_maps.sh
#Version: 1.2
#Changelog: 10/07/2020:Added handling for condition where cassandra/redis etc use a separate internal n/w interface
#Comments/Bugs:rsharma@cloudian.com
##################################################################################################################

SERVICEMAP_FILE="/opt/cloudian/conf/cloudianservicemap.json"
CASSANDRA_PID=$(jps| grep CassandraDaemon | awk '{print $1}')
CASSANDRA_PORT=9160
CASSANDRA_IP=$(ss -tlnp| grep $CASSANDRA_PID | grep $CASSANDRA_PORT  |awk '{print $4}' | cut -d ":" -f1)
CASSANDRA_INTERFACE=$(ip a | grep $CASSANDRA_IP | awk '{print $7}')

TSTAMP=$(date "+%Y.%m.%d-%H.%M.%S");
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

 echo  $INTERFACE_CLMN

}

IF_COLUMN=$(fetch_internal_interface)
echo -en  "Using column:" $IF_COLUMN
echo -en " for ethernet interface in $SERVICEMAP_FILE"
echo -e "\n"
echo "Saving token maps for ALL nodes.."

for i in `cat $SERVICEMAP_FILE | grep interfaces | awk -v N="$IF_COLUMN" '{print $N}' | sed 's/\"//g'|sed 's/\,//g'`;
    do
       echo $i >> initial_tokenmap_pernode_$TSTAMP.txt;
      echo "------------------" >> initial_tokenmap_pernode_$TSTAMP.txt;
      /opt/cloudian/bin/hsstool -h $i ring| grep -w $i >> initial_tokenmap_pernode_$TSTAMP.txt;
      echo "======================================">>initial_tokenmap_pernode_$TSTAMP.txt;
    done

echo "Done: Token Mapping for all nodes saved in initial_tokenmap_pernode_$TSTAMP.txt"
