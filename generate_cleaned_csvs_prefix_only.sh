 
#!/usr/bin/bash
Purpose: from dumped metadata matches the Hex string for the required prefix to generate smaller csv files
#that only contain this prefix, and are for a given bucket
#
prefix_to_match=0x70726f70686563792d7265636f7264696e67732d7265706c6963617465642f2e496e66696e69747953746f7261676546696c65732f5368617265642f496e6465782f70726f70686563795f7265636f7264696e675f7265702f617368732d6673322f
orig_csv_basedir=/staging/split_archived_csvs/
###RUN FROM TOOLS_HOME/bin

#orig_csv_file=splitted_csv_aj
for orig_csv_file in `ls /staging/split_archived_csvs/splitted_csv_*| grep -v splitted_csv_ai | grep -v splitted_csv_aj | grep -v splitted_csv_ak`
do
echo "cleansing: $orig_csv_file"
suffix=$(echo ${orig_csv_file: -3})
echo "DEBUG:: Suffix: $suffix"
FC_ALL=C grep $prefix_to_match $orig_csv_file >> CLEANSED_CSVS/cleansed_csv_for_$suffix
done
