TS=$(date "+%Y.%m.%d-%H.%M.%S")
HOST=`hostname`
OUTFILE=output_$HOST.$TS
KS=UserData_897e9fc17e9989a70e810cf620743737
CF=DeletedObjects

for i in `find /var/lib/cassandra/data/${KS}/${CF}-*/ -name *Data.db`
   do
     echo $i;
     echo "========================"
     /opt/cassandra/tools/bin/sstablemetadata $i
     echo "========================"
done >$OUTFILE 2>&1
