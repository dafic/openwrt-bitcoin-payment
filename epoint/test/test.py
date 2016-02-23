#!/usr/bin/python
# Copyright (C) 2009 ePoint Systems Ltd

from time import sleep
import os, random
from cookielib import CookieJar

from protocol import *
import crypto
import manage

TEST_URL = 'http://ya.ru/'
FORM_URL = 'http://192.168.1.1/cgi-bin/epoint/form.sh'

def testPayment(amount):
    print 'Testing full payment cycle'
    manage.reset()
    cookies = CookieJar()
    r = open_url(TEST_URL, cookies)
    assert r.status == 402, 'Payment Required expected'
    info = parse_form(r.content)
    assert info, 'No valid payment form found'
    r = pay_and_open(info, amount, cookies)
    assert get_meta_redirection(r.content) == TEST_URL, 'Incorrect redirection'
    r = open_url(TEST_URL, cookies)
    assert r.url == TEST_URL, 'Access not granted after successfull payment'
    print 'Passed'

def testInvalidPayment():
    amount = 100
    manage.reset()
    cookies = CookieJar()
    r = open_url(TEST_URL, cookies)
    assert r.status == 402, 'Payment Required expected before payment'
    info = parse_form(r.content)
    assert info, 'No valid payment form found'
    print 'Testing wrong issuer key'
    r = pay_and_open(info, amount, cookies, issuer=crypto.ALTERNATE_ISSUER)
    assert r.status == 402, 'Payment Required expected'
    print 'Passed'
    print 'Testing wrong target hash with correct length'
    info.target_hash = os.urandom(20)
    r = pay_and_open(info, amount, cookies)
    assert r.status == 402, 'Payment Required expected'
    print 'Passed'
    print 'Testing wrong target hash with random length'
    info.target_hash = os.urandom(random.randint(2, 50))
    r = pay_and_open(info, amount, cookies)
    assert r.status == 402, 'Payment Required expected'
    print 'Passed'
    print 'Testing wrong target key with correct length'
    info.target_hash = None
    info.target_key = os.urandom(20)
    r = pay_and_open(info, amount, cookies)
    assert r.status == 402, 'Payment Required expected'
    print 'Passed'
    print 'Testing wrong target key with random length'
    info.target_key = os.urandom(random.randint(2, 50))
    assert r.status == 402, 'Payment Required expected'
    print 'Passed'

def testHoldPayment():
    amount = 100
    wait = 20
    manage.reset()
    r = open_url(FORM_URL)
    assert r.status == 402, 'Payment Required expected before payment'
    info = parse_form(r.content)
    assert info, 'No valid payment form found'
    print 'Holding valid payment for %d seconds...' % wait
    receipt = make_receipt(info, amount)
    sleep(wait)
    r = pay_with_receipt(info, amount, receipt)
    assert r.status == 402, 'Payment required expected'
    print 'Passed'

def pay_directly(amount):
    r = open_url(FORM_URL)
    info = parse_form(r.content)
    r = pay_and_open(info, amount)

def testExpiration(amount):
    diff = manage.calc_time(amount)
    print 'Paying %d EPTs, expecting %d seconds' % (amount, diff)
    start = manage.expires()
    if start is None:
        start = manage.systime()
    pay_directly(amount)
    time_given = manage.expires() - start
    print 'Got %d seconds' % time_given
    print 'Passed' if abs(diff - time_given) < 10 else 'Failed'

def testTariffs():
    rates = [x[1] for x in manage.tariffs]
    rates.append(rates[-1] + 10000)
    print 'Testing "clean" payments'
    for low, high in zip(rates, rates[1:]):
        for x in (low, random.randint(low, high)):
            manage.reset()
            testExpiration(x)
    print 'Testing payments accumulation'
    manage.reset()
    for low, high in zip(rates[::2], rates[1::2]):
        for x in (low, random.randint(low, high), high):
            testExpiration(x)

def main():
    testPayment(100)
    testInvalidPayment()
    testTariffs()
    testHoldPayment()

if __name__ == '__main__':
    main()
