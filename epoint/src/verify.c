/*  verify - cleartext signature verification tool
    
    Copyright (C) 2010 ePoint Systems Ltd
    Author: Rooslan S. Khayrov
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
#include <gcrypt.h>
#include <opencdk.h>

static void usage(const char *progname)
{
    fprintf(stderr,
        "Usage:\n"
        "%s -k <public keyring> [-o <output clear text>] <file to verify>\n",
        progname);
}

int verify_main(int argc, char **argv)
{
    char *inpfile = NULL, *outfile = NULL, *keyfile = NULL;
    cdk_ctx_t session;
    int cdk_error;
    int opt;

    while ((opt = getopt(argc, argv, "k:o:")) > 0)
    {
        switch (opt)
        {
            case 'k':
                keyfile = optarg;
                break;
            case 'o':
                outfile = optarg;
                break;
            default:
                usage(argv[0]);
                return 2;
        }
    }
    if (!keyfile)
    {
        usage(argv[0]);
        return 2;
    }
    if (optind >= argc)
    {
        usage(argv[0]);
        return 2;
    }
    inpfile = argv[optind];

    /* opencdk does not initialize gcrypt */
    if (!gcry_check_version(GCRYPT_VERSION)) {
        fprintf(stderr, "libgcrypt initialization failed\n");
        return 1;
    }
    gcry_control(GCRYCTL_DISABLE_SECMEM,0,0,0,0,0,0,0);
    gcry_control(GCRYCTL_INITIALIZATION_FINISHED);

    if ((cdk_error = cdk_handle_new(&session)))
    {
        fprintf(stderr, "Cannot create new session: %s\n", cdk_strerror(cdk_error));
        return 1;
    }
    if ((cdk_error = cdk_handle_set_keyring(session, 0, keyfile)))
    {
        fprintf(stderr, "Cannot set session keyring: %s\n", cdk_strerror(cdk_error));
        cdk_handle_free(session);
        return 1;
    }
    if ((cdk_error = cdk_file_verify(session, inpfile, NULL, outfile)))
    {
        fprintf(stderr, "Cannot verify signature: %s\n", cdk_strerror(cdk_error));
        cdk_handle_free(session);
        return 1;
    }
    cdk_handle_free(session);

    return 0;
}
