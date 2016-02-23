# Copyright (C) 2009 ePoint Systems Ltd

import urllib

ROUTER_ADDR = 'http://192.168.1.1'

TARIFFS = 'tariffs'

MAC = None

def read_url(url):
    return urllib.urlopen(url).read()

def get_acls():
    return read_url('%s/cgi-bin/acls.sh' % ROUTER_ADDR)

def reset():
    read_url('%s/cgi-bin/reset.sh' % ROUTER_ADDR)

def get_mac():
    global MAC
    if MAC is None:
        MAC = read_url('%s/cgi-bin/getmac.sh' % ROUTER_ADDR).strip()
    return MAC

def systime():
    return int(read_url('%s/cgi-bin/systime.sh' % ROUTER_ADDR))


def strip_comment(line):
    index = line.find('#')
    return line if index < 0 else line[:index]

def parse_acl(text):
    result = {}
    for line in text.splitlines():
        a = strip_comment(line).split()
        if not a:
            continue
        assert len(a) <= 2, 'Invalid ACL file format'
        mac = a[0]
        if mac in result:
            raise ValueError('Duplicated MAC %s in ACL' % mac)
        expire = int(a[1]) if len(a) == 2 else -1
        result[mac] = expire
    return result

def expires():
    return parse_acl(get_acls()).get(get_mac())

tariffs = []

def calc_time(payment):
    for time, price in reversed(tariffs):
        if payment >= price:
            return int(float(payment) * time / price)
    return 0

def parse_tariffs():
    f = open(TARIFFS, 'r')
    for line in f:
        a = strip_comment(line).split()
        if not a:
            continue
        time, price = map(int, a[:2])
        tariffs.append((time, price))
    f.close()
    tariffs.sort()

parse_tariffs()
