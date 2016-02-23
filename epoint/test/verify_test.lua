#!/usr/bin/lua

local protocol = require('epoint.protocol')
local data = io.open('verify_test.data'):read('*a')
local key = 'verify_test.pk'

assert(protocol.verify_signature(data, key), 'verification failed')
assert(not protocol.verify_signature(data:gsub('issuer','bob'), key), 'accepted invalid signature')
print('PASS')
