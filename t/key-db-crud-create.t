## -*- mode: perl; -*-
## no critic(Modules::RequireFilenameMatchesPackage)
package
    KeyDBCRUDCreate;

use strict;
use warnings;

use Test::More;
use Test::Applify;
use lib './t/lib';
use Test::SSHKeyDB 'create_empty_db';
use Mojo::Loader 'data_section';
use SSH::PublicKey;

my ($t, $app);

$t = new_ok('Test::Applify', ['./scripts/key-db', 'add']);

#
# test filename generator
#
$app = $t->app_instance(qw{-username foo -reason this});
is $app->_generate_filename, 'foo.this.authorized_keys', 'normal';

$app = $t->app_instance(qw{-username foo -reason this.is});
is $app->_generate_filename, 'foo.this_is.authorized_keys', 'dots';

$app = $t->app_instance(qw{-username foo -reason}, 'some reason with spaces');
is $app->_generate_filename, 'foo.some_reason_with_spaces.authorized_keys', 'spaces';

$app = $t->app_instance(qw{-username fu.manchu -reason this});
is $app->_generate_filename, 'fu_manchu.this.authorized_keys', 'username dots';

$app = $t->app_instance('-user', 'fu manchu.', '-reason', 'unknown rea.son',);
is $app->_generate_filename, 'fu_manchu_.unknown_rea_son.authorized_keys', 'dots and spaces everywhere';

#
# new empty database
#
my $db = create_empty_db(Mojo::File->new($0)->basename);

#
# add one
#
$app = $t->app_instance(qw{
-public-key ./t/data/user1.shutdown.authorized_keys
-command /bin/true
-username foo
-reason test-suite
-allowed ps
-allowed ls
-key-dir}, $db->to_string);

is $app->public_key, './t/data/user1.shutdown.authorized_keys', 'key set';
is $app->command,    '/bin/true', 'command set';
is $app->username,   'foo', 'username set';
is $app->reason,     'test-suite', 'reason set';
is $app->key_dir,    $db->to_string, 'key dir set';
is_deeply $app->allowed, [qw{ps ls}], 'allowed set';

$t->run_instance_ok($app);

is $app->key_files->size, 1, 'one file';
$app->key_files->each(
    sub {
        my $name = $_->basename;
        is +($name =~ tr/\./\./), 2, 'no extraneous periods in filenames';
        my ($user, $reason) = split /\./, $name;
        is $user, 'foo', 'correct';
        is $reason, 'test-suite', 'correct again';
        my $k = SSH::PublicKey->new(val => $_->slurp);
        is $k->command, '/bin/true ps ls', 'command set';
    });

#
# add another, same name/reason, so same file.
#
$app = $t->app_instance(qw{
-public-key ./t/data/user1.shutdown.authorized_keys
-command /bin/true
-username foo
-reason test-suite
-allowed /usr/bin/tar
-nounique
-key-dir}, $db->to_string);

is $app->public_key, './t/data/user1.shutdown.authorized_keys', 'key set';
is $app->command,    '/bin/true', 'command set';
is $app->username,   'foo', 'username set';
is $app->reason,     'test-suite', 'reason set';
is $app->key_dir,    $db->to_string, 'key dir set';
is_deeply $app->allowed, ['/usr/bin/tar'], 'allowed set';

$t->run_instance_ok($app);

is $app->key_files->size, 1, 'one file';

#
# add another, unique hopefully
#
$app = $t->app_instance(qw{
-public-key ./t/data/user2.ps.authorized_keys
-command /bin/only
-allowed df
-username bar
-reason test-suite
-key-dir}, $db->to_string);

is $app->public_key, './t/data/user2.ps.authorized_keys', 'key set';
is $app->command,    '/bin/only', 'command set';
is $app->username,   'bar', 'username set';
is $app->reason,     'test-suite', 'reason set';
is $app->key_dir,    $db->to_string, 'key dir set';
is_deeply $app->allowed, ['df'], 'allowed set';

$t->run_instance_ok($app);

is $app->key_files->size, 2, 'two files';

#
# add another, non-unique, but pass the nounique flag
#
$app = $t->app_instance(qw{
-public-key ./t/data/user2.ps.authorized_keys
-command /bin/true
-username bazza.nologin
-reason test-suite
--allowed who
--allowed du
-nounique
-key-dir}, $db->to_string);

is $app->public_key, './t/data/user2.ps.authorized_keys', 'key set';
is $app->command,    '/bin/true', 'command set';
is $app->username,   'bazza.nologin', 'username set';
is $app->reason,     'test-suite', 'reason set';
is $app->key_dir,    $db->to_string, 'key dir set';
is_deeply $app->allowed, [qw{who du}], 'allowed set';

$t->run_instance_ok($app);

is $app->key_files->size, 3, 'three files';
$app->key_files->each(
    sub {
        my $name = $_->basename;
        is +($name =~ tr/\./\./), 2, 'no extraneous periods in filenames';
    });

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
command="/bin/only df",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAAEEEE= passphraseless key `test-suite`
@@ bazza_nologin.test-suite.authorized_keys
command="/bin/true who du",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAAEEEE= passphraseless key `test-suite`
@@ foo.test-suite.authorized_keys
command="/bin/true /usr/bin/tar",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAA= passphraseless key `test-suite`
@@ last
