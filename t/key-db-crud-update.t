## -*- mode: perl; -*-

package 
    test;

use strict;
use warnings;

use Test::More;
use Test::Applify;
use lib './t/lib';
use Test::SSHKeyDB 'create_db';
use Mojo::Loader 'data_section';
use SSH::PublicKey;

my ($t, $app, $exited, $stdout, $stderr);

$t = new_ok('Test::Applify', ['./scripts/key-db', 'update']);

my $db = create_db(Mojo::File->new($0)->basename);

#
# update one 
#
$app = $t->app_instance(qw{
-public-key ./t/data/user1.shutdown.authorized_keys 
-command /sbin/only
-username foo
-reason test-suite-2
-allowed ps
-allowed ls
-key-dir}, $db->to_string);

is $app->public_key, './t/data/user1.shutdown.authorized_keys', 'key set';
is $app->command,    '/sbin/only', 'command set';
is $app->username,   'foo', 'username set';
is $app->reason,     'test-suite-2', 'reason set';
is $app->key_dir,    $db->to_string, 'key dir set';
is_deeply $app->allowed, [qw{ps ls}], 'allowed set';

($exited, $stdout, $stderr) = $t->run_instance_ok($app);

is $exited, 0, 'successful run';

like $stdout, qr/^renamed:/m, 'file was renamed message';
like $stdout, qr/^updating:/m, 'file was updated message';
is $stderr, '', 'no messages';



#
# check database is as expected
#

$app->key_files->map(
    sub {
	# __PACKAGE__ needs a package definition above
	my $exp = data_section(__PACKAGE__, $_->basename);
	my $obs = $_->slurp;
	is $obs, $exp, 'content match ' . $_->basename;
});

done_testing();

__DATA__
@@ bar.test-suite.authorized_keys
command="/bin/true ",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAAEEEE= passphraseless key `test-suite`
@@ foo.test-suite-2.authorized_keys
command="/sbin/only ps ls",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAA= passphraseless key `test-suite-2`
@@ last
