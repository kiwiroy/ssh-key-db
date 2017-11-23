## -*- mode: perl; -*-
## no critic(Modules::RequireFilenameMatchesPackage)
package
    KeyDBCrudRead;

use strict;
use warnings;

use Test::More;
use Test::Applify;

use lib './t/lib';
use Test::SSHKeyDB 'create_db';

my ($t, $app, $exited, $stdout, $stderr);

$t = new_ok('Test::Applify', ['./scripts/key-db', 'list']);

my $db = create_db(Mojo::File->new($0)->basename);
my @opt = qw{-command /sbin/nologin};
#
# select all
#
$app = $t->app_instance(@opt, qw{-key-dir}, $db->to_string);

is $app->key_files->size, 2, 'two files';

($exited, $stdout, $stderr) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';

like $stdout, qr/^user:\sbar$/m, 'bar user';
like $stdout, qr/^user:\sfoo$/m, 'foo user';


#
# select by user
#
$app = $t->app_instance(@opt, qw{-user foo -key-dir}, $db->to_string);

($exited, $stdout, $stderr) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';

unlike $stdout, qr/^user:\sbar$/m, 'no bar user';
like   $stdout, qr/^user:\sfoo$/m, 'has foo user';


#
# select by public key
#
$app = $t->app_instance(qw{
-public-key ./t/data/user1.shutdown.authorized_keys 
-reason test-suite
-key-dir}, $db->to_string);

($exited, $stdout, $stderr) = $t->run_instance_ok($app);

is $exited, 0, 'did not exit';
diag $stderr if $exited;

is +($stdout =~ s/^(filename:)/$1/gm), 1, 'results';
like $stdout, qr/^user:\sfoo$/m, 'correct user';

#
# select by both public key and username - distinctly different predicates
# i.e. key is for user foo, but we select on bar too.
#
$app = $t->app_instance(qw{
-public-key ./t/data/user1.shutdown.authorized_keys 
-username bar
-reason test-suite
-key-dir}, $db->to_string);

($exited, $stdout, $stderr) = $t->run_instance_ok($app);

is $exited, 0, 'did not exit';
diag $stderr if $exited;

is +($stdout =~ s/^(filename:)/$1/gm), 2, 'results';
like $stdout, qr/^user:\sbar$/m, 'bar user';
like $stdout, qr/^user:\sfoo$/m, 'foo user';

#
# select by both public key and username
# (selects the same key, which might give 2 results, but they should be unique)
#
$app = $t->app_instance(qw{
-public-key ./t/data/user2.ps.authorized_keys 
-username bar
-reason test-suite
-key-dir}, $db->to_string);

is $app->public_key, './t/data/user2.ps.authorized_keys', 'key set';
is $app->username,   'bar', 'username set';
is $app->key_dir,    $db->to_string, 'key dir set';

($exited, $stdout, $stderr) = $t->run_instance_ok($app);

is $exited, 0, 'did not exit';
diag $stderr if $exited;

is +($stdout =~ s/^(filename:)/$1/gm), 1, 'results';

like $stdout, qr{^filename:\s$db}m, 'correct file';
like $stdout, qr/^user:\sbar$/m, 'correct user';
like $stdout, qr/^reason:\stest\-suite$/m, 'correct reason';
like $stdout, qr{^command:\s/bin/true$}m, 'correct command';
like $stdout, qr/^key:\sAAAAAAEEEE=$/m, 'correct key';
like $stdout, qr/^type:\sssh\-rsa$/m, 'correct type';

done_testing();
