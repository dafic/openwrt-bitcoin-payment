#!/bin/sh

KEY=verify_test.pk
DOC=verify_test.data

epoint_verify -k $KEY $DOC && echo 'OK'

