## -*- mode: perl; -*-
package Test::SSHKeyDB;

use strict;
use warnings;

use base 'Exporter';

use IO::String;

use Mojo::File qw{tempdir};
use Mojo::Home;
use Mojo::Util 'monkey_patch';

use Test::Applify;

our @EXPORT_OK = qw{create_db create_empty_db};

sub create_db {
    my ($t, $app);
    my $name = shift;
    my $home = Mojo::Home->new->detect;
    my $data = $home->child(qw{t data});
    my $db   = tempdir("$name.XXXXX", DIR => $data, CLEANUP => 1);
    my @opts = qw{-command /bin/true -reason test-suite};

    $t = Test::More::new_ok('Test::Applify', [qw{./scripts/key-db add}]);
    $app = $t->app_instance(@opts, qw{
-public-key ./t/data/user1.shutdown.authorized_keys
-username foo
-key-dir}, $db->to_string);
    $app->run;

    $app = $t->app_instance(@opts, qw{
-public-key ./t/data/user2.ps.authorized_keys
-username bar
-key-dir}, $db->to_string);
    $app->run;

    Test::More::is $app->key_files->size, 2, 'wrote both files';

    return $db;
}

sub create_empty_db {
    my $name = shift;
    my $home = Mojo::Home->new->detect;
    my $data = $home->child(qw{t data});
    return tempdir("$name.XXXXX", DIR => $data, CLEANUP => 1);
}

monkey_patch 'Test::Applify', run_instance_ok => sub {
    my $self = shift;
    my $instance = shift;

    $self->_test('ok', $instance, 'pass run_instance_ok return from app_instance');
    $self->_test('like', ref($instance), qr/^Applify\:\:/, 'application class');
    $self->_test('can_ok', $instance, '_script');

    my ($stdout, $stderr, $exited) = ('', '', 0);
    #local (*STDOUT, *STDERR);
    #open STDOUT, '>', \$stdout;
    #open STDERR, '>', \$stderr;
    tie *STDOUT, 'IO::String', \$stdout;
    tie *STDERR, 'IO::String', \$stderr;

    local *CORE::GLOBAL::exit = sub (;$) { $exited = 1; };
    my $retval = eval { $instance->run() };
    # no warnings 'once' and https://stackoverflow.com/a/25376064
    *CORE::GLOBAL::exit = *CORE::exit;

    untie *STDOUT;
    untie *STDERR;

    return ($exited, $stdout || $@, $@ || $stderr, $retval);
};

monkey_patch 'Test::Applify', run_ok => sub {
    my $self = shift;
    $self->run_instance_ok($self->app_instance(@_));
};



1;
