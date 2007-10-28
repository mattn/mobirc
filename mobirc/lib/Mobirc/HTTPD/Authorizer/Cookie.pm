package Mobirc::HTTPD::Authorizer::Cookie;
use strict;
use warnings;
use boolean ':all';
use Carp;
use CGI::Cookie;

sub authorize {
    my ( $class, $c, $conf ) = @_;

    unless ($c->{config}->{httpd}->{use_cookie}) {
        croak "$class needs enable config->httpd->use_cookie flag";
    }

    my %cookie = CGI::Cookie->parse($c->{req}->header('Cookie'));

    if (   $cookie{username}->value eq $conf->{username}
        && $cookie{passwd}->value eq $conf->{password} )
    {
        return true;
    }
    else {
        return false;
    }
}

1;
