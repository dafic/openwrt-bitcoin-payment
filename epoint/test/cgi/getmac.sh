#!/bin/sh

echo 'Status: 200 OK'
echo 'Content-type: text/plain; charset=us-ascii'
echo

grep $REMOTE_ADDR /proc/net/arp | awk '{print $4}'
