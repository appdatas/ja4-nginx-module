# vi:filetype=perl
# Test::Nginx tests for ngx_http_ssl_ja4_module.
#
# Client: Test::Nginx default (Perl IO::Socket, plain HTTP/1.1).
# Scope: module load, plain-HTTP safety when JA4 variables are referenced.
# Not covered here: TLS ClientHello / JA4 golden fingerprints (see test/*.py).
#
# Run (requires nginx built with this module + Test::Nginx):
#   export TEST_NGINX_BINARY=/path/to/nginx
#   export PERL5LIB=$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}
#   export TEST_NGINX_SERVROOT=$PWD/test/servroot
#   prove -v test/plain-http-variables.t

BEGIN {
    use File::Spec;
    $ENV{TEST_NGINX_SERVROOT} ||= File::Spec->rel2abs('test/servroot');
}

use Test::Nginx::Socket 'no_plan';

repeat_each(1);
no_shuffle();
run_tests();

__DATA__

=== TEST 1: module_loads (JA4H variable is registered)
# JA4H is HTTP-layer and works without TLS. A non-empty value proves the
# module was compiled in and its variables are available to the rewrite
# engine.
--- config
    location /t {
        default_type text/plain;
        return 200 "ja4h=$http_ssl_ja4h\n";
    }
--- request
GET /t
--- response_body_like chomp
^ja4h=ge11nn



=== TEST 2: plain_http_no_crash (SSL JA4 vars on plain HTTP)
# On non-TLS connections ngx_ssl_ja4() declines; handlers must not crash
# the worker. Current behavior substitutes an empty value (not 500).
--- config
    location /t {
        default_type text/plain;
        return 200 "ja4=$http_ssl_ja4 ja4_string=$http_ssl_ja4_string ja4one=$http_ssl_ja4one ja4s=$http_ssl_ja4s ja4s_string=$http_ssl_ja4s_string ja4l=$http_ssl_ja4l\n";
    }
--- request
GET /t
--- response_body
ja4= ja4_string= ja4one= ja4s= ja4s_string= ja4l=



=== TEST 3: no_error_on_missing_ssl (mixed dump including JA4H)
# Reference SSL + HTTP JA4 variables together on plain HTTP. SSL-derived
# fields stay empty; JA4H is still computed from the request line/headers.
--- config
    location /t {
        default_type text/plain;
        return 200 "ja4=$http_ssl_ja4 ja4h=$http_ssl_ja4h\n";
    }
--- request
GET /t
--- response_body_like chomp
^ja4= ja4h=ge11nn
