# Copyright (C) 2009 ePoint Systems Ltd

from HTMLParser import HTMLParser
import urllib, urllib2, cookielib
from binascii import unhexlify
import re

import crypto

class FormParser(HTMLParser):
    def __init__(self):
        # it's an old-style class...
        HTMLParser.__init__(self)
        self.in_form = False
        self.fields = {}
        self.target_hash = None
        self.redirect_url = None
    
    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        attrs = dict((k.lower(), v) for k, v in attrs)
        if tag == 'form' and attrs['action'].endswith('/action'):
            self.in_form = True
        elif self.in_form and tag == 'input' and attrs['type'] in ('text', 'hidden'):
            self.fields[attrs['name']] = attrs.get('value')
    
    def handle_endtag(self, tag):
        if tag.lower() == 'form':
            if self.in_form:
                if 'B' in self.fields and 'G' in self.fields:
                    self.target_hash = self.fields.get('D')
                    self.target_key = self.fields.get('KEY')
                    self.redirect_url = self.fields['G']
            self.in_form = False
            self.fields.clear()

class PaymentInfo(object):
    def __init__(self, target_hash, target_key, redirect_url):
        self.target_hash = target_hash
        self.target_key = target_key
        self.redirect_url = redirect_url

def parse_form(html):
    '''
    Extracts payment information from HTML form. Returns object with two fields: 
    'target_hash' and 'redirect_url'. Returns None if valid payment form is not found.
    '''
    parser = FormParser()
    parser.feed(html)
    parser.close()
    if (parser.target_hash or parser.target_key) and parser.redirect_url:
        assert not (parser.target_hash and parser.target_key), \
            "Both D and KEY fields are present."
        return PaymentInfo(
            parser.target_hash and unhexlify(parser.target_hash),
            parser.target_key and unhexlify(parser.target_key),
            parser.redirect_url)
    else:
        return None

class MetaTagParser(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.redirect_url = None
    
    def handle_starttag(self, tag, attrs):
        if tag.lower() == 'meta':
            attrs = dict((k.lower(), v) for k, v in attrs)
            if attrs.get('http-equiv', '').lower() == 'refresh' and 'content' in attrs:
                m = re.match(r'\d+\s*;\s*url\s*=\s*(.+)$', attrs['content'], re.I | re.M)
                if m:
                    self.redirect_url = m.groups(0)[0]

def get_meta_redirection(html):
    '''
    Provided HTML document, returns URL of meta refresh. Returns None if valid 
    meta tag is not found.
    '''
    parser = MetaTagParser()
    parser.feed(html)
    parser.close()
    return parser.redirect_url

class HTTPResponse(object):
    def __init__(self, status, url, content=''):
        self.status = status
        self.url = url
        self.content = content

class HTTPPaymentHandler(urllib2.HTTPDefaultErrorHandler):
    def http_error_default(self, req, fp, code, msg, hdrs):
        if code != 402:
            return urllib2.HTTPDefaultErrorHandler.http_error_default(self, req, fp, code, msg, hdrs)
        result = urllib2.HTTPError(req.get_full_url(), code, msg, hdrs, fp)
        result.status = code
        return result

def open_url(url, cookies=None):
    '''
    Opens HTTP URL following redirections and handling 402 Payment Required errors. 
    Returns object with three fields: 'status' (numerical HTTP status),
    'url' (retrieved URL), and 'content' (HTTP response body).
    Optional 'cookies' should contain cookielib.CookieJar cookies container.
    '''
    if cookies is None:
        cookies = cookielib.CookieJar()
    opener = urllib2.build_opener(HTTPPaymentHandler(), urllib2.HTTPCookieProcessor(cookies))
    try:
        response = opener.open(url)
        result = HTTPResponse(response.code, response.geturl(), response.read())
        response.close()
        return result
    except urllib2.HTTPError, e:
        return HTTPResponse(e.code, e.geturl())

def make_receipt(info, amount, issuer=crypto.DEFAULT_ISSUER):
    target = info.target_hash or (info.target_key + '\0')
    return crypto.make_receipt(amount, target, issuer)

def pay_with_receipt(info, amount, receipt, cookies=None):
    if cookies is None:
        cookies = cookielib.CookieJar()
    url = info.redirect_url
    if url.endswith('='):
        url = url + urllib.quote(receipt)
    elif url.endswith('?'):
        url = url[:-1] + str(amount)
    return open_url(url, cookies)

def pay_and_open(info, amount, cookies=None, issuer=crypto.DEFAULT_ISSUER):
    '''
    info - object with 'target_hash' and 'redirect_url' fields, as returned by
    parse_form.
    amount - number of EPTs.
    '''
    receipt = make_receipt(info, amount, issuer)
    return pay_with_receipt(info, amount, receipt, cookies)
