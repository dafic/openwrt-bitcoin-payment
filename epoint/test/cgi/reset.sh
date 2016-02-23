#!/bin/sh

echo 'Status: 200 OK'
echo 'Content-type: text/plain; charset=us-ascii'
echo

MAC=`grep $REMOTE_ADDR /proc/net/arp | awk '{print $4}'`

TMP=`mktemp /tmp/acl.XXXXXX`

. /usr/lib/epoint/tariffs

for acl in `acl_files`; do
    grep -v $MAC $acl > $TMP
    mv -f $TMP $acl
done
rm -f $TMP

/usr/sbin/update-rules

echo 'Done.'
