#!/usr/bin/python
# Copyright (C) 2009 ePoint Systems Ltd

import os, struct

GNUPG_BINARY = '/usr/bin/gpg'

DEFAULT_ISSUER='mod_payment'
ALTERNATE_ISSUER='issuer_2'

def signed(data, issuer, use_v4_sig=False):
    """
    """
    voption = '--no-force-v3-sigs' if use_v4_sig else '--force-v3-sigs'
    gpgin, gpgout = os.popen2(
        '%s -s -z0 --rfc2440 %s --no-textmode --default-key %s' % \
        (GNUPG_BINARY, voption, issuer))
    gpgin.write(data)
    gpgin.close()
    result = gpgout.read()
    gpgout.close()
    return result

def make_receipt(value, target, issuer=DEFAULT_ISSUER):
    literal = struct.pack('>I', value) + target
    return signed(literal, issuer)

if __name__ == '__main__':
    import sys
    value, target, issuer = sys.argv[1:4]
    value = int(value)
    sys.stdout.write(make_receipt(value, target, issuer))
