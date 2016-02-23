#!/usr/bin/awk -f
# Copyright (C) 2008 ePoint Systems Ltd

BEGIN {
    ORS = "\r\n"
    
    reasons[303] = "See Other"
    reasons[400] = "Bad Request"
    reasons[501] = "Not Implemented"
    
    content_type = "Content-Type: text/html; charset=iso-8859-1"
    
    redirect_path = "/cgi-bin/epoint/form"
    
    "getsockname" | getline local_ip
    if (!local_ip) {
        # fall back to old solution
        "uci get network.lan.ipaddr" | getline local_ip
    }
}

function timestamp() {
    # BusyBox awk implementation doesn't support UTC flag in strftime
    # return strftime("%a, %e %b %Y %H:%M:%S GMT", systime(), 1)
    "date -uR" | getline dt
    sub(/\+0000|UTC/, "GMT", dt)
    return dt
}

function start_response(status) {
    return sprintf("HTTP/1.1 %d %s\r\nDate: %s\r\nServer: ePoint httpd (Linux/OpenWRT)\r\nConnection: close",
        status, reasons[status], timestamp())
}

function bad_request() {
    printf("%s\r\n%s\r\n\r\n<html><body><h1>400 Bad Request</h1></body></html>",
        start_response(400), content_type)
}

function not_implemented() {
    printf("%s\r\n%s\r\n\r\n<html><body><h1>501 Not Implemented</h1><p>Only GET is supported</p></body></html>",
        start_response(501), content_type)
}

function redirect(uri) {
    printf("%s\r\nLocation: %s\r\n\r\n", start_response(303), uri)
}

function urlencode(s) {
    for (c = 1; c < 256; ++c) {
        ord[sprintf("%c", c)] = c
    }
    result = ""
    for (i = 1; i <= length(s); ++i) {
        c = substr(s, i, 1)
        if (c ~ /[a-zA-Z0-9.-]/) {
            result = result c
        } else if (c == " ") {
            result = result "+"
        } else {
            result = result sprintf("%%%02X", ord[c])
        }
    }
    return result
}

FNR==1 {
    if ($1 == "GET") {
        uri = $2
    } else {
        not_implemented()
        exit
    }
}

/^Host:/ {
    host = $2
}

/^\r$/ {
    if (ENVIRON["REMOTE_HOST"] && system("[ -e /usr/sbin/roam-update ] && /usr/sbin/roam-update >/dev/null 2>/dev/null && has-access $REMOTE_HOST >/dev/null") == 0) {
        # hack: to avoid login form if client has access (on demand roam acl update)
        redirect_path = "/cgi-bin/epoint/status"
    }
    if (!host) {
        redirect(sprintf("http://%s%s", local_ip, redirect_path))
        exit
    }
    if (substr(uri, 1, 1) != "/") {
        uri = "/"uri
    }
    redirect(sprintf("http://%s%s?G=%s", local_ip, redirect_path, urlencode("http://" host uri)))
    exit
}
