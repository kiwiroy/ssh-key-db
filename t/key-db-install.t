## -*- mode: perl; -*-
## no critic(Modules::RequireFilenameMatchesPackage)
package
    KeyDBInstall;

use strict;
use warnings;

use Test::More;
use Test::Applify;
use lib './t/lib';
use Test::SSHKeyDB 'create_db';
use Mojo::Loader 'data_section';
use SSH::PublicKey;

my ($t, $app, $exited, $stdout, $stderr, $retval);

$t = new_ok('Test::Applify', ['./scripts/key-db', 'install']);

my $db = create_db(Mojo::File->new($0)->basename);
my @opts = (qw{-key-dir}, $db->to_string);

my $input = data_section __PACKAGE__, 'input';
my $output =  data_section __PACKAGE__, 'output';


my $auth_key = $db->child('authorized_keys.install');
$auth_key->spurt($input);

#
# install
#
$app = $t->app_instance(@opts, qw{--authorized-keys}, $auth_key->to_string);

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'successful run';
is $retval, 0, 'successful retval';

like $stdout, qr/^wrote:/m, 'write message';
like $stdout, qr/^installed:/m, 'installed message';
is $stderr, '', 'no messages';

is $auth_key->slurp, $output, 'installed correct keys';

$app = $t->app_instance(@opts, qw{--authorized-keys}, $auth_key->to_string . '-does-not-exist');

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'successful run';
is $retval, 1, 'successful retval';

is $stdout, '', 'no messages here';
like $stderr, qr/^file does not exist/, 'no file message';


done_testing();


__DATA__
@@ input
ssh-rsa AAAAAEEAEEEAEAEEAEAEEEEA= remain
ssh-rsa AAAAAEEATTTTTTTTTAEAEEEEA= remain
command="/sbin/only who df",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAAEEEE= remove
command="/sbin/only ps",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAA= remove
@@ output
ssh-rsa AAAAAEEAEEEAEAEEAEAEEEEA= remain
ssh-rsa AAAAAEEATTTTTTTTTAEAEEEEA= remain
command="/bin/true",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAAEEEE= passphraseless key `test-suite`
command="/bin/true",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAA= passphraseless key `test-suite`
@@ last
