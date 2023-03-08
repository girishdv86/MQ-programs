for i in qm1 qm2
do
   endmqm -i $i
   endmqlsr -m $i
   dltmqm $i
   crtmqm $i
   strmqm $i
done

# -------------------------------------------------------------------------------------------------- #
# This is a sample script to show activity trace and monitoring for trace messages                   #
# This is a two qmgrs setup with topic and sub on qm1 and destination queue of the sub pointing      #
# to an alias queue in turn to a remote queue which points to a local queue of qm2. Sample program   #
# amqsact is used to monitor activity trace message on queue TRACE.ACTIVITY. Here, we are monitoring #
# only activity trace message for channel GEN.SVRCONN. To trigger the activity trace amqsputc        #
# sample is used to connect to qm1 using channel GEN.SVRCONN. The script can be run without any      #
# paramter. A sample run can be:                                                                     #
#            . ./setup_actvttrace.sh                                                                 #
# After a successful run a file named activity.msg is created which contains the activity trace      #
# message receives on qm2                                                                            #
# -------------------------------------------------------------------------------------------------- #

runmqlsr -m qm1 -t tcp -p 8989 &
runmqlsr -m qm2 -t tcp -p 8990 &

echo  "alter qmgr ACTVTRC(ON)" |runmqsc  qm1
echo  "alter qmgr CHLAUTH(DISABLED) connauth(' ')" |runmqsc qm1
echo  "refresh security type(connauth)" | runmqsc qm1
echo "alter ql(SYSTEM.ADMIN.TRACE.ACTIVITY.QUEUE) maxdepth(999999999)" |runmqsc qm1
echo "def chl(GEN.SVRCONN) CHLTYPE(SVRCONN) mcauser('mqm')" | runmqsc qm1
echo "def ql(LQ)" | runmqsc qm1

echo "def topic(TOPIC.TRACE.ACTIVITY.GEN.SVRCONN) topicstr('\$SYS/MQ/INFO/QMGR/qm1/ActivityTrace/ChannelName/GEN.SVRCONN') PUB(ENABLED) SUB(ENABLED) MDURMDL(SYSTEM.DURABLE.MODEL.QUEUE) MNDURMDL(SYSTEM.NDURABLE.MODEL.QUEUE) MCAST(DISABLED) USEDLQ(NO) replace" | runmqsc qm1
echo "def qa(ALIAS.TRACE.ACTIVITY) target(QR1)" |runmqsc qm1
echo "def qr(QR1) rname(TRACE.ACTIVITY) rqmname('qm2') xmitq(XQ)" | runmqsc qm1
echo "def ql(XQ) usage(xmitq)" | runmqsc qm1
echo "def SUB(SUB.TRACE.ACTIVITY.GEN.SVRCONN) topicstr('\$SYS/MQ/INFO/QMGR/qm1/ActivityTrace/ChannelName/GEN.SVRCONN') dest(ALIAS.TRACE.ACTIVITY)" |runmqsc qm1
echo "def chl(CHL1) chltype(sdr) conname('localhost(8990)') xmitq(XQ)" | runmqsc qm1

echo "def ql(TRACE.ACTIVITY) maxdepth(999999999)" | runmqsc qm2
echo "def chl(CHL1) chltype(rcvr)" | runmqsc qm2

echo "start chl(CHL1)" | runmqsc qm1

export MQSERVER='GEN.SVRCONN/TCP/127.0.0.1(8989)'

amqsact -m qm2 -w 5 -q TRACE.ACTIVITY > activity.msg &

amqsputc LQ qm1 << TEST_MSG
tintin
TEST_MSG

echo Sleep for 10 seconds to make amqsact timed-out
sleep 10
echo End of run.....Check file activity.msg

