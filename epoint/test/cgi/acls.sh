#!/bin/sh

echo 'Status: 200 OK'
echo 'Content-type: text/plain; charset=us-ascii'
echo

. /usr/lib/epoint/tariffs

for acl in `acl_files`; do
    echo "# FILE: $acl"
    cat $acl
done
