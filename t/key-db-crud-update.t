## -*- mode: perl; -*-
## no critic(Modules::RequireFilenameMatchesPackage)
package
    KeyDBCRUDUpdate;

use strict;
use warnings;

use Test::More;
use Test::Applify;

use Mojo::Home;
use Mojo::Loader 'data_section';
use SSH::PublicKey;

use lib './t/lib';
use Test::SSHKeyDB 'create_db';

my ($t, $app, $exited, $stdout, $stderr, $retval);

$t = new_ok('Test::Applify', ['./scripts/key-db', 'update']);

my $db = create_db(Mojo::File->new($0)->basename);
my @opts = (qw{-key-dir}, $db->to_string);

#
# update one
#
$app = $t->app_instance(@opts, qw{
-public-key ./t/data/user1.shutdown.authorized_keys
-command /sbin/only
-username foo
-reason test-suite-2
-allowed ps
-allowed ls});

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
# do not update one - no command or allowed
#
$app = $t->app_instance(@opts, qw{
-public-key ./t/data/user1.shutdown.authorized_keys
-username baz
-reason test-suite-2});

($exited, $stdout, $stderr, $retval) = $t->run_instance_ok($app);

is $exited, 0, 'successful run';
is $retval, 1, 'return value';
like $stderr, qr/supply either -allowed or -command or both/;
unlike $stderr, qr/^renamed:/, 'file was not renamed';

#
# do not update another one - allowed but no command
#


my $data = Mojo::Home->new->detect->child(qw{t data});
## username and reason passed to match
$app = $t->app_instance(qw{
-public-key ./t/data/user1.shutdown.authorized_keys
-username user1
-allowed ps
-reason shutdown
--key-dir}, $data->to_string);

($exited, $stdout, $stderr, $retval) = $t->run_instance_ok($app);

is $exited, 0, 'successful run';
is $retval, 2, 'return value';
like $stderr, qr/^no command to update/m, 'failed update message';


#
# check database is as expected
#
$app = $t->app_instance(@opts);
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
