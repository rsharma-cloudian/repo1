 #!/bin/bash
##################################################################################################################
##Purpose: Analyzes Bucket Logger Output
#Version: 1.1
#Comments/Bugs:rsharma@cloudian.com

################Beautifying!! #####################

WORKING_DIR=`pwd`
TS=$(date "+%Y.%m.%d-%H.%M.%S")
OUTPUTFILE=$WORKING_DIR/bucket_logger_analysis_$TS.txt
#GREEN='\033[0;32m'
GREEN='\e[30;48;5;82m'
NOCOLOR='\033[0m'
MAGENTA='\e[45m'
LIGHTPURPLE='\033[1;35m'
LIGHTRED='\033[1;31m'
DARKGRAY='\033[1;30m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'

function separator {
echo -e "${LIGHTPURPLE}==============================================================${NOCOLOR}"
}

####################CLI Options ##########################################################

usage()
{
 cat<< EOF
usage: $0 --dest [--firstlook] [--prefix |--depth|--unique-folder-count|--h]
This script analyzes bucket logger output.
Use --dest <destination_of_bucket_logger> --firstlook for basic analysis.
Use options below to find files stored under a prefix, at a certian folder depth, or the number of unique folders at specified depth
Use --h for options
OPTIONS:
    --h Show this message
    --dest <destination_of_bucket_logger> --firstlook ==> Analyzes basic information from the collected logs
    --dest <destination_of_bucket_logger> --prefix <prefix_within_bucket> ==> Analyzes information about specified prefix
    --dest <destination_of_bucket_logger> --prefix <prefix_within_bucket> --depth <N> ==> Analyzes information about specified prefix at the specified depth
    --dest <destination_of_bucket_logger> --unique-folder-count --depth <N> ==> Get count of unique folders at the specified depth
EOF
}


###########################################################Usage###############

        firstlook()
	{
	echo -e "${CYAN}BucketLogger Path:${NOCOLOR}${DARKGRAY}$BUCKETLOGGER_PATH${NOCOLOR}" |tee -a $OUTPUTFILE
	separator
	echo -e "${CYAN}Scanning Logfile for Errors:${NOCOLOR}" |tee -a $OUTPUTFILE
	RET=`grep ERROR $TOOLLOG | head -1`
	if [[ $RET == "" ]]
   		then
   			echo "No Errors in cloudian-tools.log" |tee -a $OUTPUTFILE
		else
    			echo -e ${YELLOW}"Error(s) were encountered while collecting bucket logger. Captured entries may be incompete." |tee -a $OUTPUTFILE
    			echo -e "Aborting Analysis." |tee -a $OUTPUTFILE
    			echo -e ${LIGHTRED}"$RET" |tee -a $OUTPUTFILE
    			separator
    			exit 1
	fi

	separator
	echo -en "${CYAN}Bucket Name:${NOCOLOR} " |tee -a $OUTPUTFILE
	echo -en ${ORANGE}
	cat $TOOLLOG | grep 'contains' | grep scanBucket | grep objects | awk '{print $7}'|tee -a $OUTPUTFILE

	separator

	echo -en "${CYAN}Is versioning enabled?:${NOCOLOR} " |tee -ai $OUTPUTFILE
	echo -en ${ORANGE}
	OBJFILE=`find $BUCKETLOGGER_PATH -name objs.txt.?.log`
	RET=`LC_ALL=C egrep 'true|false'  $OBJFILE | head -1|grep -w null`

	if [[ $RET == "" ]]
   		then
   			echo "Yes, Bucket is Versioned" |tee -a $OUTPUTFILE
    			VERSIONED=1
 		else
    			echo "No, Bucket is not versioned" |tee -a $OUTPUTFILE
    			VERSIONED=0
	fi

	separator
	echo -en "${CYAN}Number of cassandra partitions: ${NOCOLOR} " |tee -a $OUTPUTFILE
	echo -en ${ORANGE}
	NUMRKS=`wc -l $RKFILE | awk '{print $1}'`
        echo $NUMRKS |tee -a $OUTPUTFILE
	separator

	echo -en "${CYAN}Number of Objects:${NOCOLOR} " |tee -a $OUTPUTFILE
	echo -en ${ORANGE}
	NUMOBJS=`find $BUCKETLOGGER_PATH -name cloudian-tools.log| xargs grep 'contains' | grep scanBucket | grep objects | awk '{print $9}'`
        echo $NUMOBJS |tee -a $OUTPUTFILE
	separator

        echo -en "${CYAN}Average number of objects per partitions:${NOCOLOR} " |tee -a $OUTPUTFILE
        echo -en ${ORANGE}
	echo $((NUMOBJS / NUMRKS))|tee -a $OUTPUTFILE
	separator

	echo -e "${CYAN}Sample Entry for objects: $PREFIX:${NOCOLOR}" |tee -a $OUTPUTFILE
        echo -e ${ORANGE}
        SAMPLEOBJ=`LC_ALL=C head -20 $OBJFILE |tail -1`
	echo $SAMPLEOBJ |tee -a $OUTPUTFILE
        char='/'
        OBJDEPTH=`echo "${SAMPLEOBJ}" | awk -F"${char}" '{print NF-1}'`
        echo -e "${CYAN}Object exists at depth: "${LIGHTRED}$OBJDEPTH${NOCOLOR}
	while [ $OBJDEPTH -ge 2 ];
		do
		   echo -en "${ORANGE}Depth $[OBJDEPTH - 1]:${NOCOLOR}";
		   echo $SAMPLEOBJ|cut  -f $OBJDEPTH -d / ;
		   (( --OBJDEPTH ));
		   echo "=-=--=-=-=--=-=";
                done |tee -a $OUTPUTFILE
        separator

	if [[ $VERSIONED -eq "1" ]]
		then
			echo -e "${CYAN}Total Number of Delete Markers across the whole bucket:${NOCOLOR}" |tee -a $OUTPUTFILE
			echo -e ${DARKGRAY}"Running: 'LC_ALL=C cat $OBJFILE | awk -F '|' '{print \$3}' | grep -w true | wc -l'"
			echo -e ${DARKGRAY}"on Filesize: `ls  -lh $OBJFILE | awk '{print $5 " " $9}'`"
			echo -e ${ORANGE}
			LC_ALL=C cat $OBJFILE | awk -F '|' '{print $3}' | grep -w true | wc -l |tee -a $OUTPUTFILE
			separator
	fi
	echo "Generated Logfile: $OUTPUTFILE"
        }   ##End of firstlook


#################################analyzeprefix########

        analyzeprefix()
	{
	echo -e "${CYAN}BucketLogger Path:${NOCOLOR}${DARKGRAY}$BUCKETLOGGER_PATH${NOCOLOR}" |tee -a $OUTPUTFILE
	separator
	echo -e "${CYAN}Scanning Logfile for Errors:${NOCOLOR}" |tee -a $OUTPUTFILE
	RET=`grep ERROR $TOOLLOG | head -1`
	if [[ $RET == "" ]]
   		then
   			echo "No Errors in cloudian-tools.log" |tee -a $OUTPUTFILE
   			echo "Bucket Logger collection was successful" |tee -a $OUTPUTFILE
		else
    			echo -e ${YELLOW}"Error(s) were encountered while collecting bucket logger. Captured entries may be incompete." |tee -a $OUTPUTFILE
    			echo -e "Aborting Analysis." |tee -a $OUTPUTFILE
    			echo -e ${LIGHTRED}"$RET" |tee -a $OUTPUTFILE
    			separator
    			exit 1
	fi

	separator
	echo -en "${CYAN}Bucket Name:${NOCOLOR} " |tee -a $OUTPUTFILE
	echo -en ${ORANGE}
	#cat $TOOLLOG | grep 'contains' | grep scanBucket | grep objects | awk '{print $7}'|tee -a $OUTPUTFILE
	BUCKETNAME=`cat $TOOLLOG | grep 'contains' | grep scanBucket | grep objects | awk '{print $7}'`
	echo -en "${CYAN}Bucket Prefix:${NOCOLOR}" |tee -a $OUTPUTFILE
	echo -e "${DARKGRAY}$PREFIX"
        #echo -en
	separator

	echo -en "${CYAN}Is versioning enabled?:${NOCOLOR} " |tee -ai $OUTPUTFILE
	echo -en ${ORANGE}
	OBJFILE=`find $BUCKETLOGGER_PATH -name objs.txt.?.log`
	RET=`LC_ALL=C egrep 'true|false'  $OBJFILE | head -1|grep -w null`

	if [[ $RET == "" ]]
   		then
   			echo "Bucket is Versioned" |tee -a $OUTPUTFILE
    			VERSIONED=1
 		else
    			echo "Bucket is not versioned" |tee -a $OUTPUTFILE
    			VERSIONED=0
	fi

	separator
	echo -en "${CYAN}Number of cassandra partitions (rowkeys):${NOCOLOR}" |tee -a $OUTPUTFILE
	echo -en ${ORANGE}
	wc -l $RKFILE | awk '{print $1}' |tee -a $OUTPUTFILE
	separator

	echo -en "${CYAN}Number of Objects under $PREFIX:${NOCOLOR}" |tee -a $OUTPUTFILE
	echo -en ${ORANGE}
	#LC_ALL=C fgrep $PREFIX $OBJFILE| awk -F '|' '{print $3}'| egrep 'true|false' | wc -l |tee -a $OUTPUTFILE
	LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE| awk -F '|' '{print $3}'| egrep 'true|false' | wc -l |tee -a $OUTPUTFILE

	if [[ $VERSIONED=1 ]]
           then
               echo -e "${ORANGE}The above count is inclusive of any Delete Markers"|tee -a $OUTPUTFILE
           else
               echo -e "${ORANGE}No DMs in the above count since bucket is non versioned"|tee -a $OUTPUTFILE
        fi

	echo -e "${CYAN}Sample object under: $PREFIX:${NOCOLOR}" |tee -a $OUTPUTFILE
        echo -e ${YELLOW}
        SAMPLEOBJ=`LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE | head -1`
        echo $SAMPLEOBJ |tee -a $OUTPUTFILE
        char='/'
        OBJDEPTH=`echo "${SAMPLEOBJ}" | awk -F"${char}" '{print NF-1}'`
        echo -e "${CYAN}In this sample, Object exists at depth: "${LIGHTRED}$OBJDEPTH${NOCOLOR}
        while [ $OBJDEPTH -ge 2 ];
                do
                   echo -en "${ORANGE}Depth $[OBJDEPTH - 1]:${NOCOLOR}";
                   echo $SAMPLEOBJ|cut  -f $OBJDEPTH -d / ;
                   (( --OBJDEPTH ));
                   echo "=-=--=-=-=--=-=";
                done |tee -a $OUTPUTFILE
	separator

	if [[ $VERSIONED -eq "1" ]]
		then
			echo -e "${CYAN}Total Number of Delete Markers under partition:$PREFIX:${NOCOLOR}" |tee -a $OUTPUTFILE
			echo -e "${GREY}(can take very long ..an hour or two for large buckets..)"
			echo -e ${DARKGRAY}"Running: 'time LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE | awk -F '|' '{print \$3}' | grep -w true | wc -l'"
			echo -e ${DARKGRAY}"on Filesize: `ls  -lh $OBJFILE | awk '{print $5 " " $9}'`"
			echo -e ${ORANGE}
			LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE | awk -F '|' '{print $3}' | grep -w true | wc -l |tee -a $OUTPUTFILE
			separator
	fi
	echo "Generated Logfile: $OUTPUTFILE"
        }   ##End of firstlook

##########################analyzeprefix-depth##############################################################

       analyzeprefix-depth(){
       BUCKETNAME=`cat $TOOLLOG | grep 'contains' | grep scanBucket | grep objects | awk '{print $7}'`
       echo -en "Number of files at depth $DEPTH: "
       DEPTHSEEK=$(( DEPTH += 1 ))
       LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE| cut -f $DEPTHSEEK -d / |egrep 'true|false' | wc -l |tee -a $OUTPUTFILE
       echo -e ${DARKGRAY}"To view Object names run: 'LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE| cut -f $DEPTHSEEK -d / |egrep 'true|false''"

        separator
        echo -e "${CYAN}Sample objects for prefix: $PREFIX:${NOCOLOR}" at specified depth |tee -a $OUTPUTFILE
        echo -e ${ORANGE}
        #SAMPLEOBJ=`LC_ALL=C head -20 $OBJFILE |tail -1`
	#SAMPLEOBJ=`LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE | head -20| tail -1`
	#SAMPLEOBJ=`LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE | head -20| tail -1`
 	LC_ALL=C fgrep "$BUCKETNAME/$PREFIX" $OBJFILE| cut -f $DEPTHSEEK -d / |egrep 'true|false' |head -10
        #echo $SAMPLEOBJ |tee -a $OUTPUTFILE
        char='/'
        #OBJDEPTH=`echo "${SAMPLEOBJ}" | awk -F"${char}" '{print NF-1}'`
        #echo -e "${CYAN}In this sample, object exists at depth: "${LIGHTRED}$OBJDEPTH${NOCOLOR}
        #while [ $OBJDEPTH -ge 2 ];
        #        do
        #           echo -en "${ORANGE}Depth $[OBJDEPTH - 1]:${NOCOLOR}";
        #           echo $SAMPLEOBJ|cut  -f $OBJDEPTH -d / ;
        #           (( --OBJDEPTH ));
        #           echo "=-=--=-=-=--=-=";
        #        done |tee -a $OUTPUTFILE
        separator
	}


#######################################################case ###################################3

case "$1" in
	--firstlook)
        BUCKETLOGGER_PATH=$2
               if [ "$#" -ne 3 ]
           	then
                	echo "--firstlook must be used after specifying --dest. Expecting destination path of bucket logger."
                	echo "Eg: $0 --dest /loganalysis/path-to-extracted-bucket-logger/ --firstlook"
                	exit 1
           	else
                	echo "performing firstlook.."
        		firstlook;
               fi
	;;
	--dest)
        BUCKETLOGGER_PATH=$2
        OBJFILE=`find $BUCKETLOGGER_PATH -name objs.txt.?.log`
	RKFILE=`find $BUCKETLOGGER_PATH -name rk.txt.?.log`
	TOOLLOG=`find $BUCKETLOGGER_PATH -name cloudian-tools.log`
                        if [[ ("$1" == '--dest') && ("$3" == '--firstlook') ]]
                then
                        echo "performing firstlook.."
                                firstlook;
                elif
                       [[ ("$1" == '--dest') && ($3 == '--prefix') && ("$#" -eq 4) ]]
                        then
                                USERPREFIX=$4
				UPREFIX_STARTCHK=`echo $USERPREFIX |cut -c1-1`
                                if [ $UPREFIX_STARTCHK == '/' ]
                                   then
                                      echo "Please specify Prefix without a '/' as the first character"
				      exit 1
                                fi

                        	echo "Analyzing the logs for: --dest $BUCKETLOGGER_PATH  --prefix $USERPREFIX" |tee -a $OUTPUTFILE
                        	LC_ALL=C fgrep -q $USERPREFIX $RKFILE
                                PREFIX_MATCH_IN_RK=$?
                                if [[ $PREFIX_MATCH_IN_RK -eq "0" ]]
   	 		        then
                                        PREFIX=$USERPREFIX
       					analyzeprefix;
       				else
           			echo "Could Not find the prefix: $USERPREFIX in $RKFILE" |tee -a $OUTPUTFILE
                                echo "Please re-run with the closest matching prefix that exists in $RKFILE"|tee -a $OUTPUTFILE
           			exit 1;
        			fi
                        elif
			   [[ ("$1" == '--dest') && ($3 == '--unique-folder-count') && ($4 == '--depth') && ("$#" -eq 5) ]]
                            then
                                DEPTH="$5"
				#echo  "DEPTH set to::$DEPTH"
				echo  "Reading Object List from::$OBJFILE"
				echo -e "Getting unique folder count at depth:$DEPTH"
				DEPTHSEEK=$(( DEPTH += 1 ))
                                echo -e ${YELLOW}
				LC_ALL=C cat $OBJFILE  |  cut -f $DEPTHSEEK -d / | sort |uniq -c |grep -v '|' | awk '{print $2}'|sed '/^$/d'|wc -l
				echo -e ${DARKGRAY}"To get the list of unique folder names, run:"
				echo -e ${DARKGRAY}"LC_ALL=C cat $OBJFILE  |  cut -f $DEPTHSEEK -d / | sort |uniq -c |grep -v '|' | awk '{print \$2}'|sed '/^$/d'"
			elif
			   [[ ("$1" == '--dest') && ($3 == '--prefix') && ($5 == '--depth') && ("$#" -eq 6) ]]
			    then
				DEPTH="$6"
				USERPREFIX=$4

				UPREFIX_STARTCHK=`echo "$USERPREFIX" |cut -c1-1`
                                if [ $UPREFIX_STARTCHK == '/' ]
                                   then
                                      echo "Please specify Prefix without a '/' as the first character"
				      exit 1;
                                fi

                                 echo -e "${CYAN}Analyzing the logs for:${NOCOLOR}"

				echo -e "\t --dest ${YELLOW}$BUCKETLOGGER_PATH${NOCOLOR}"
                                echo -e "\t --prefix ${YELLOW}$USERPREFIX${NOCOLOR}"
				echo -e "\t --depth ${YELLOW}$DEPTH${NOCOLOR}"
                                LC_ALL=C fgrep -q $USERPREFIX $RKFILE
                                PREFIX_MATCH_IN_RK=$?
                                	if [[ $PREFIX_MATCH_IN_RK -eq "0" ]]
                                	then
                                        PREFIX=$USERPREFIX
                                        analyzeprefix-depth;
                                	else
                                	echo "Could Not find the prefix: $USERPREFIX in $RKFILE" |tee -a $OUTPUTFILE
                                	echo "Please re-run with the closest matching prefix that exists in $RKFILE"|tee -a $OUTPUTFILE
                                	exit 1;
                                	fi
                                exit 0
                        else
                        	echo "--firstlook or --prefix or --unique-folder-count after--dest. Expecting more arguments."
                        	echo "Eg: $0 --dest /loganalysis/path-to-extracted-bucket-logger/ --firstlook"
                        	echo "Eg: $0 --dest /loganalysis/path-to-extracted-bucket-logger/ --prefix /var/www/html"
                        	echo "Eg: $0 --dest /loganalysis/path-to-extracted-bucket-logger/ --unique-folder-count --depth 4"
                        	exit 1
               fi
               separator

	;;
	--prefix)
	echo "analyzing for prefix"
        exit 0
        ;;
        --depth)
        if [ "$#" -ne 4 ]
           then
    	        echo "--depth must be used with --prefix. Expecting values for --depth and --prefix"
                echo "Eg: $0 --prefix /var/www/html --depth 4"
    		exit 1
           else
                echo " checking for depth d"
	fi
        exit 0
        ;;
	--h)
		usage
		exit 1
	;;
	*) if [[("$#" -le 3) ]]
            then
		usage
		exit
            fi
esac

##############################################################################
