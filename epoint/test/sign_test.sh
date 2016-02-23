#!/bin/sh

# epoint_verify cannot work with dsatool generated keys
# so the verification cannot be done on the router

set -e

KEY=daaaa
DIR=/tmp/$KEY
DSA=dsatool
SIGN=./main
VERIFY="gpg --homedir=$DIR --verify"

mkdir -p $DIR
echo $KEY | $DSA -s >$DIR/secring.gpg
echo $KEY | $DSA -p >$DIR/pubring.gpg

echo hello world! >$DIR/hello.txt
$SIGN $DIR/secring.gpg <$DIR/hello.txt >$DIR/hello.txt.sig
#epoint_verify -k daaaa/pubring.gpg -o hello.txt.sig.txt hello.txt.sig
$VERIFY <$DIR/hello.txt.sig

rm -rf $DIR

