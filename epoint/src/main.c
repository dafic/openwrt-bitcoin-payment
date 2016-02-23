#include <stdio.h>
#include <string.h>

#include "b64decode.h"
extern int sign_main(int argc, char *argv[]);
extern int verify_main(int argc, char *argv[]);
extern int dsatool_main(int argc, char *argv[]);

static int endswith(const char *s1, const char *s2)
{
    size_t len1 = strlen(s1), len2 = strlen(s2);
    if (len1 < len2)
        return 0;
    return !strcmp(s1 + len1 - len2, s2);
}

typedef struct
{
    const char *exename;
    int (*mainptr)(int, char**);
} entry_point;

entry_point entry_points[] = {
    { "epoint_dsakey", dsatool_main },
    { "epoint_verify", verify_main },
    { "epoint_sign", sign_main },
    { "b64decode", b64decode_main },
    { NULL, NULL } };

static void usage()
{
    size_t i = 0;
    fputs(
        "Usage: <function> [arguments]\n"
        "Available functions:\n",
        stderr);
    while (entry_points[i].exename)
    {
        fprintf(stderr, "%s\n", entry_points[i].exename);
        ++i;
    }
}

int main(int argc, char **argv)
{
    size_t i = 0;
    while (entry_points[i].exename)
    {
        if (endswith(argv[0], entry_points[i].exename))
        {
            return entry_points[i].mainptr(argc, argv);
        }
        ++i;
    }
    usage();
    return 2;
}
