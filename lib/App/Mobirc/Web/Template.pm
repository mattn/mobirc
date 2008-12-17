package App::Mobirc::Web::Template;
use strict;
use warnings;
use App::Mobirc;

our $REQUIRE_WRAP;

{
    # template eval. context.
    package App::Mobirc::Web::Template::Run;
    use Encode qw/encode_utf8 decode_utf8/;
    use App::Mobirc::Pictogram ();
    use Path::Class;

    *encoded_string = *Text::MicroTemplate::encoded_string;
    sub pictogram { encoded_string(App::Mobirc::Pictogram::pictogram(@_)) }
    sub global_context  () { App::Mobirc->context   } ## no critic
    sub web_context () { App::Mobirc::Web::Handler->web_context } ## no critic
    sub param { decode_utf8(web_context()->req->param($_[0])) }
    sub xml_header {
        encoded_string( join "\n",
            q{<?xml version="1.0" encoding="UTF-8" ?>},
            q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">}
        );
    }
    sub include {
        my ($path, @args) = @_;
        App::Mobirc->context->mt->render_file(
            "${path}.mt",
            @args,
        );
    }
    sub render_irc_message { include('parts/irc_message', shift) }
    sub server          () { global_context->server } ## no critic.
    sub config          () { global_context->config } ## no critic.
    sub docroot {
        (config->{httpd}->{root} || '/')
    }
    sub load_assets {
        my @path = @_;
        join '', file(config->{global}->{assets_dir}, @path)->slurp
    }
    sub mobile_attribute () { web_context()->mobile_attribute() }
    sub is_iphone { (mobile_attribute()->user_agent =~ /(?:iPod|iPhone)/) ? 1 : 0 }
    sub require_wrap { $App::Mobirc::Template::REQUIRE_WRAP++ };
}

1;
