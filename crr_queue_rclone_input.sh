TS=$(date "+%Y.%m.%d-%H.%M.%S")
IP="10.0.34.8"
OUTFILE=output_$HOST.$TS
KS=UserData_c2c82ca21c8b1e987d516a3a2ca47d6c
CF=BucketReplication
BUCKETNAME=cldnbkt
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
NOCOLOR='\033[0m'

function separator {
echo -e "${LIGHTPURPLE}==============================================================${NOCOLOR}"
}

echo -e "Finding Replication Queue entries for the bucket:${BUCKETNAME}"
echo -e "Fetching entries in the Replication Queue for all buckets in ${CYAN}$KS${NOCOLOR}"
echo "select key, blobastext(key) from \"${KS}\".\"${CF}\" where column1='D' allow filtering;" |  /opt/cassandra/bin/cqlsh ${IP} > original_br_list_${TS}.txt

echo "Saved in:original_br_list_${TS}.txt"
separator;

echo -e "Getting version count for bucket:${CYAN}${BUCKETNAME}${NOCOLOR} from file:original_br_list_${TS}.txt"

	for file in `grep 0x original_br_list_${TS}.txt | grep ${BUCKETNAME}|awk -F '|' '{print $2}'`
 	   do
   		echo $file|sed -e 's/"$//' |sed -e "s/^$BUCKETNAME\///" |  sed 's/\\.*//';
		done | uniq -c > version_count_${BUCKETNAME}_${TS}.txt
echo "Saved in: version_count_${BUCKETNAME}_${TS}.txt"
separator;

echo "From version count list, getting the list of files that have a single version..saving to: rclone_input_list_${BUCKETNAME}_${TS}.txt"
	awk '{if($1=="1")print $0}' version_count_${BUCKETNAME}_${TS}.txt | awk '{print $2}' > rclone_input_list_${BUCKETNAME}_${TS}.txt

echo "Preparing the list of files in the queue with  > 1 versions : (multi_version_files_${BUCKETNAME}_${TS}.txt"
	awk '{if($1!="1")print $0}' version_count_${BUCKETNAME}_${TS}.txt | awk '{print $2}' > multi_version_files_${BUCKETNAME}_${TS}.txt
        echo "Saved in: version_count_${BUCKETNAME}_${TS}.txt"
        MULTIVERSION_COUNT=`wc -l multi_version_files_${BUCKETNAME}_${TS}.txt| awk '{print $1}'`
 	if [[ $MULTIVERSION_COUNT -eq 0 ]]
            then
            echo "There are no entries in the queue with multiple versions of same file"
        fi
separator;


echo "Filter out a list of rows that do not contain files with > 1 versions: "

        if [[ $MULTIVERSION_COUNT -eq 0 ]]
           then
 	     for key in `grep 0x original_br_list_${TS}.txt  | grep $BUCKETNAME|awk -F '|' '{print $1}'`
		do
		echo $key
		done >delete_keys_${BUCKETNAME}_${TS}.txt
          else
		for filename in `cat multi_version_files_${BUCKETNAME}_${TS}.txt`
	  	   do
			grep -v $filename original_br_list_${TS}.txt| grep 0x|grep $BUCKETNAME|awk -F '|' '{print $1}'
	  	done >delete_keys_${BUCKETNAME}_${TS}.txt
       fi
echo "Saved in:delete_keys_${BUCKETNAME}_${TS}.txt"
separator;

##########################################
###OPTIONAL: To inspect the delete entries, following check may be performed.
###Requires vim-common package installed to get xxd binary.

##for key in `cat delete_keys_$BUCKETNAME_$TS.txt`
##do
##echo $key| xxd -r -p; echo "";
##done
##########################################
echo "Next Steps:"
echo "1. Use the file:rclone_input_list_${BUCKETNAME}_${TS}.txt as input to rclone"
echo "Example:"
echo -e "${CYAN}rclone copy --files-from rclone_input_list_${BUCKETNAME}_${TS}.txt cloudian1:SOURCE_BKT  cloudian2:DESTINATION_BKT -P --no-update-modtime --transfers 32 -c -vv${NOCOLOR}"
echo -e "\n"
echo "2. Delete the rows in repication queue for ${BUCKETNAME} for the rows copied via rclone, using the file:delete_keys_${BUCKETNAME}_${TS}.txt"
echo "Example:"
echo -en "${CYAN}"
echo -e 'for key in `cat delete_keys_cldnbkt_2020.12.16-11.04.49.txt`; do echo "DELETE from \"${KS}\".\"${CF}\" where key=$key;"|  /opt/cassandra/bin/cqlsh ${IP}; done'
echo -e "${NOCOLOR}"
separator;
