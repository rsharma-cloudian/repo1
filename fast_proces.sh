#!/usr/bin/bash
####Purpose: Generates csv list to provide listing of large buckets that have aged beynd a predefined date-stamp
####         Uses inputs as multiple parsed metadata files in JSON format
#### 
###          Change Line 10 to specify a different path for json-parsed files from CLOUDIAN_METADATA entries

PROCESSED_FILE_COUNT=0
BUCKETNAME=prophecy-recordings-replicated

###CQLMD_cleansed_csv_for__* are JSON files containing parsed metadata from CLOUDIAN_TOOLS/cloudian-cass-parser

for JSONFILE in `ls /root/aspect_ashs-fs2/CLEANSED_JSON/CQLMD_cleansed_csv_for__*`
  do
      echo "Processing json file:$JSONFILE"
      SOURCEFILE=$(echo "$JSONFILE" |cut -d / -f 5)
      time FC_ALL=C cat $JSONFILE | jq -r '[.Path,.Version,.DeleteMarker,.WriteTime]  | @csv' |  sed -e 's/"//g' | sed -e "s/^$BUCKETNAME\///" | rev | cut -c19- | rev >>flist_"$SOURCEFILE".csv
      echo -en "Entries Processed from Sourcefile:"
      FC_ALL=C wc -l flist_"$SOURCEFILE".csv
      echo "Filtering entries written on or before::" `date -d @1597537519 --utc`

      LC_ALL=C cat flist_"$SOURCEFILE".csv | awk -F ','  '{if($4 < 1597537519) print $0}' >>list_"$SOURCEFILE".out
      echo $?
      echo "Generated List:" list_"$SOURCEFILE".out
      echo -en "Qualified Files:"
      FC_ALL=C wc -l list_"$SOURCEFILE".out

      (( ++PROCESSED_FILE_COUNT ))
      echo "Processed Files: $PROCESSED_FILE_COUNT"
 done
