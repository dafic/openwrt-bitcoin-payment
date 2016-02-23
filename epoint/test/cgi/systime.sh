#!/bin/sh

echo 'Status: 200 OK'
echo 'Content-type: text/plain; charset=us-ascii'
echo

awk 'BEGIN { print systime() }'
