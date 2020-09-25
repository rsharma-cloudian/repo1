##Generates json file for each cleaned CSV file

export TOOL_HOME=/staging/cloudian-bucket-tools
export CLOUDIAN_HOME=/opt/cloudian
CSVDIR=/staging/cloudian-bucket-tools/bin/CLEANSED_CSVS/

for cleansed_csv in `ls /staging/cloudian-bucket-tools/bin/CLEANSED_CSVS/`
do
        echo "processing: $cleansed_csv"
        date; time ./cloudian-cass-parser -f $CSVDIR$cleansed_csv -cf 1
        echo "Return Code: $?"
        resulting_file=`ls -lrt CQLMD* | tail -1 | awk '{print $9}'`
        echo "Generated JSON file: $resulting_file"
        echo "Moving $resulting_file to CLEANSED_CSVS/CLEANSED_JSON/"
        mv $resulting_file CLEANSED_CSVS/CLEANSED_JSON/
        echo "=-=-=-=-=-=-=-=-==-=-=-=-=-=--=-=-=-=-=-=-=-=-=-"
done
