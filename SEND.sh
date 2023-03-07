crtmqm SEND
crtmqm RECV
strmqm SEND
strmqm RECV


echo "define qlocal(TRANSMIT) usage(xmitq)" | runmqsc SEND
echo "define qremote(REMOTEQ) rname(Q6) rqmname(RECV) xmitq(TRANSMIT)"  | runmqsc SEND
echo "define channel(STOR) chltype(SDR) conname('localhost(2012)')  xmitq(TRANSMIT) trptype(TCP)"  | runmqsc SEND
echo "start channel(STOR)" | runmqsc SEND


echo "def ql(Q1)" | runmqsc RECV
echo "define channel(STOR) chltype(RCVR) trptype(TCP)" | runmqsc RECV
echo "define listener(LISTENER) trptype(tcp) control(qmgr) port(2012)" | runmqsc RECV
echo "start listener(LISTENER)" | runmqsc RECV

