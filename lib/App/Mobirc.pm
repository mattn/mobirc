package App::Mobirc;
use strict;
use warnings;
use 5.00800;
use Scalar::Util qw/blessed/;
use POE;
use App::Mobirc::ConfigLoader;
use App::Mobirc::Util;
use App::Mobirc::HTTPD;
use UNIVERSAL::require;
use Carp;
use App::Mobirc::Channel;
use Encode;

our $VERSION = '0.06';

our $HasKwalify;
eval {
    require Kwalify;
    $HasKwalify++;
};

my $context;
sub context { $context }

sub new {
    my ($class, $config_stuff) = @_;
    my $config = App::Mobirc::ConfigLoader->load($config_stuff);
    my $self = bless {config => $config, channels => {}}, $class;

    $self->load_plugins;

    $context = $self;

    return $self;
}

sub load_plugins {
    my ($self,) = @_;
    die "this is instance method" unless blessed $self;

    for my $plugin (@{$self->config->{plugin}}) {
        DEBUG "LOAD PLUGIN: $plugin->{module}";
        $plugin->{module}->use or die $@;
        if ( $HasKwalify && $plugin->{module}->can('config_schema') ) {
            my $res = Kwalify::validate( $plugin->{module}->config_schema, $plugin->{config} );
            unless ( $res == 1 ) {
                die "config.yaml validation error : $plugin->{module}, $res";
            }
        }
        $plugin->{module}->register( $self, $plugin->{config} );
    }
}

sub config { shift->{config} }

sub run {
    my $self = shift;
    die "this is instance method" unless blessed $self;

    for my $code (@{$self->get_hook_codes('run_component')}) {
        $code->($self);
    }

    App::Mobirc::HTTPD->init($self->config);

    $poe_kernel->run();
}

sub register_hook {
    my ($self, $hook_point, $code) = @_;
    die "this is instance method" unless blessed $self;
    croak "code required" unless ref $code eq 'CODE';

    push @{$self->{hooks}->{$hook_point}}, $code;
}

sub get_hook_codes {
    my ($self, $hook_point) = @_;
    die "this is instance method" unless blessed $self;
    croak "hook point missing" unless $hook_point;
    return $self->{hooks}->{$hook_point} || [];
}

# -------------------------------------------------------------------------

sub add_channel {
    my ($self, $channel) = @_;
    croak "missing channel" unless $channel;

    $self->{channels}->{$channel->name} = $channel;
}

sub channels {
    my $self = shift;
    my @channels = values %{ $self->{channels} };
    return wantarray ? @channels : \@channels;
}

sub get_channel {
    my ($self, $name) = @_;
    croak "channel name is flagged utf8" unless Encode::is_utf8($name);
    croak "invalid channel name : $name" if $name =~ / /;
    return $self->{channels}->{$name} ||= App::Mobirc::Channel->new($self, $name);
}

sub delete_channel {
    my ($self, $name) = @_;
    croak "channel name is flagged utf8" unless Encode::is_utf8($name);
    delete $self->{channels}->{$name};
}

1;
__END__

=head1 NAME

App::Mobirc - pluggable IRC to HTTP gateway

=head1 DESCRIPTION

mobirc is a pluggable IRC to HTTP gateway for mobile phones.

=head1 CODE COVERAGE

I use Devel::Cover to test the code coverage of my tests, below is the Devel::Cover report on this module test suite.

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/App/Mobirc.pm         80.0   35.7   62.5   87.0    0.0   10.5   66.5
    ...lib/App/Mobirc/Channel.pm   77.3   53.6   66.7   81.2   14.3    1.7   68.3
    ...pp/Mobirc/ConfigLoader.pm   94.3   50.0   72.7  100.0    0.0   24.4   81.8
    blib/lib/App/Mobirc/HTTPD.pm   63.3    0.0    0.0   85.2    0.0    2.9   56.4
    ...obirc/HTTPD/Controller.pm   38.9   19.4    0.0   61.3    0.0    2.7   35.6
    ...pp/Mobirc/HTTPD/Router.pm   40.9    0.0    n/a   85.7    0.0    5.5   30.0
    ...lib/App/Mobirc/Message.pm  100.0    n/a    n/a  100.0  100.0    0.7  100.0
    ...n/Authorizer/BasicAuth.pm   48.0    0.0    0.0   57.1    0.0    0.1   38.1
    ...ugin/Authorizer/Cookie.pm   44.7    0.0    0.0   53.8    0.0    0.1   37.8
    ...horizer/EZSubscriberID.pm   48.0    0.0    0.0   57.1    0.0    0.1   40.0
    .../Authorizer/SoftBankID.pm   52.2    0.0    0.0   57.1    0.0    0.0   42.1
    ...in/Component/IRCClient.pm   83.2   33.3   41.7   83.3    0.0    8.3   72.1
    .../Mobirc/Plugin/DocRoot.pm   80.6   25.0    n/a   75.0    0.0    2.8   69.8
    ...PS/InvGeocoder/EkiData.pm   93.8   75.0    n/a  100.0    0.0    3.9   90.9
    ...S/InvGeocoder/Nishioka.pm   93.3   50.0    n/a  100.0    0.0    1.8   90.0
    ...TMLFilter/CompressHTML.pm   90.9    n/a    n/a   80.0    0.0    0.2   85.7
    ...lter/ConvertPictograms.pm   84.6    n/a    n/a   80.0    0.0    0.8   78.9
    ...n/HTMLFilter/DoCoMoCSS.pm   37.5    0.0    n/a   66.7    0.0    0.2   35.3
    ...n/IRCCommand/TiarraLog.pm   21.4    0.0    0.0   57.1    0.0    0.1   18.4
    ...geBodyFilter/Clickable.pm   92.8   83.3   72.7   83.3    0.0    8.7   85.1
    ...ageBodyFilter/IRCColor.pm   77.3   64.3  100.0   81.8    0.0    0.9   72.4
    blib/lib/App/Mobirc/Util.pm   100.0   50.0    n/a  100.0    0.0   23.8   86.3
    Total                          66.6   32.1   36.0   78.1    2.8  100.0   59.1
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Tokuhiro Matsuno and Mobirc AUTHORS.

=head1 LICENSE

GPL 2.0 or later.
