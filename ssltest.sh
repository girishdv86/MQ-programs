#!/bin/sh
THISPWD=`pwd`

### source /home/mckechan/.env/test_profile_linux 7016

QM1=SSLQM1REFRESH
QM2=SSLQM2REFRESH
QMGRS=( $QM1 $QM2 )

PW1=wibble
QMPATH=/var/mqm/qmgrs/

TRACE=$THISPWD/trace
FILES=$THISPWD/files

rm -f /var/mqm/errors/*
rm -f $TRACE/*
rm -f $FILES/*

mkdir $FILES

################################################################
# Set up Queue Manager
################################################################
for qmgr in "${QMGRS[@]}" ; do
  dspmq | grep $qmgr | grep Running
  if [ $? -eq 0 ] ; then
    endmqm -i $qmgr
  fi
  ps auwx | grep $qmgr | grep -v grep
  if [ $? -eq 0 ] ; then
    pids=`ps auwx | grep $qmgr | grep -v grep | awk '{print $2}'`
    for pid in $pids; do
      kill -9 $pid
    done
  fi
  dspmq | grep $qmgr
  if [ $? -eq 0 ] ; then
    dltmqm $qmgr
  fi
  if [ -d /var/mqm/qmgrs/$qmgr ]; then
    sudo /bin/rm -rf /var/mqm/qmgrs/$qmgr
  fi
  if [ -d /var/mqm/sockets/$qmgr ]; then
    sudo /bin/rm -rf /var/mqm/sockets/$qmgr
  fi
  if [ -d /var/mqm/log/$qmgr ]; then
    sudo /bin/rm -rf /var/mqm/log/$qmgr
  fi
  if [ -d /var/mqm/errors/$qmgr ]; then
    sudo /bin/rm -rf /var/mqm/errors/$qmgr
  fi

  crtmqm $qmgr
  strmqm $qmgr

done


#===============================================================
echo "DEFINE CHANNEL( TO."$QM1" ) CHLTYPE( RCVR ) "\
     "TRPTYPE( TCP ) DESCR( 'Receiver for $QM1' ) "\
     "SSLCIPH(TLS_RSA_WITH_AES_256_CBC_SHA256) "\
     "SSLCAUTH( REQUIRED )"                                     | runmqsc $QM1

echo "Creating Listener"
#===============================================================
echo "STOP LISTENER( SYSTEM.DEFAULT.LISTENER )"                 | runmqsc $QM1
echo "STOP LISTENER( "$QM1".LISTENER ) MODE( TERMINATE )"       | runmqsc $QM1
echo "DELETE LISTENER( "$QM1".LISTENER )"                       | runmqsc $QM1
echo "DEFINE LISTENER( "$QM1".LISTENER ) TRPTYPE( TCP ) "\
     "PORT( 3361 ) REPLACE"                                     | runmqsc $QM1
echo "START LISTENER( "$QM1".LISTENER )"                        | runmqsc $QM1
echo "DEFINE QL(Q1)" |runmqsc $QM1
echo ""

#===============================================================
echo "DEFINE QLOCAL( XMIT.TO.$QM1 ) USAGE( XMITQ )"             | runmqsc $QM2
echo "DEFINE CHANNEL( TO."$QM1" ) CHLTYPE( SDR ) "\
     "TRPTYPE( TCP ) DESCR( 'Sender to $QM1' ) " \
     "XMITQ( XMIT.TO.$QM1 )" \
     "SSLCIPH(TLS_RSA_WITH_AES_256_CBC_SHA256) CONNAME( 'localhost(3361)' ) "        | runmqsc $QM2

echo "DEFINE QR(REMOTEQ) RNAME(Q1) RQMNAME("$QM1") XMITQ(XMIT.TO.$QM1)" |runmqsc $QM2
# Create certificates
#=============================================================================

QM1LABEL=ibmwebspheremqsslqm1refresh
QM2LABEL=ibmwebspheremqsslqm2refresh

QMDB1=/var/mqm/qmgrs/$QM1/ssl/key.kdb
QMDB2=/var/mqm/qmgrs/$QM2/ssl/key.kdb

set -x
# Key databases
runmqckm -keydb -create -pw $PW1 -db $QMDB1 -type cms -stash
runmqckm -keydb -create -pw $PW1 -db $QMDB2 -type cms -stash

# Self-signed QMGR1 cert
runmqckm -cert -create  -db $QMDB1 -pw $PW1 -label $QM1LABEL -dn "CN=qm1,O=IBM,OU=Test,C=UK" -size 1024 -ca true

# Self-signed QMGR2 cert
runmqckm -cert -create  -db $QMDB2 -pw $PW1 -label $QM2LABEL -dn "CN=qm2,O=IBM,OU=Test,C=UK" -size 1024 -ca true

# Extract cert from key db
runmqckm -cert -extract -db $QMDB1 -pw $PW1 -label $QM1LABEL -target $FILES/qm1.pem
runmqckm -cert -extract -db $QMDB2 -pw $PW1 -label $QM2LABEL -target $FILES/qm2.pem

runmqckm -cert -add     -db $QMDB2 -pw $PW1 -label $QM1LABEL -file   $FILES/qm1.pem
runmqckm -cert -add     -db $QMDB1 -pw $PW1 -label $QM2LABEL -file   $FILES/qm2.pem

chmod 660 /var/mqm/qmgrs/$QM1/ssl/*
chmod 660 /var/mqm/qmgrs/$QM2/ssl/*
set +x

#strmqtrc -e -t all -t detail
strmqtrc -t all -t detail -m $QM1
strmqtrc -t all -t detail -m $QM2

sleep 5
echo "START CHANNEL(TO.$QM1)"       | runmqsc $QM2
sleep 10
echo "DIS CHSTATUS(TO.$QM1)"        | runmqsc $QM2
date

#echo "REFRESH SECURITY TYPE(SSL)" | runmqsc $QM1
#echo "REFRESH SECURITY TYPE(SSL)" | runmqsc $QM2
#sleep 5

#endmqtrc -a

#gsk8trc AMQ.SSL.TRC > AMQ.SSL.FMT
#gsk7trc AMQ.SSL.TRC > AMQ.SSL.FMT 

#cd $THISPWD

# endmqm -i $QM1
# endmqm -i $QM2


