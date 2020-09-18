#!/bin/bash

##rsharma@cloudian.com

###Script to Identify the prefix:prophecy-recordings-replicated/.InfinityStorageFiles/Shared/Index/prophecy_recording_rep/ashs-fs2/
###from "CLOUDIAN_METADATA" Table in Cassandra
##Version 1.0 09/18/2020

###################
##CUSTOM_VARIABLES: Change as per the customer's config
custom_prefix=0x70726f70686563792d7265636f7264696e67732d7265706c6963617465642f2e496e66696e69747953746f7261676546696c65732f5368617265642f496e6465782f70726f70686563795f7265636f7264696e675f7265702f617368732d6673322f
csv_set_prefix=splitted_csv_

for file in `ls $csv_set_prefix*`
	do
	   echo "Scanning $file for $custom_prefix .."
	   FC_ALL=C fgrep -q $custom_prefix $file
	   if [[ $? == 0 ]]
	     then
		echo "$file contains $custom_prefix" >>csvs_containing_prefix.out
	   else
		echo "$file does not contain $custom_prefix. We can IGNORE\!"
	   fi
done
