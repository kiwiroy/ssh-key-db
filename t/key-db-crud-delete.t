## -*- mode: perl; -*-
## no critic(Modules::RequireFilenameMatchesPackage)
use strict;
use warnings;

use Test::More;
use Test::Applify;

use lib './t/lib';
use Test::SSHKeyDB 'create_db';

my ($t, $app, $exited, $stdout, $stderr, $retval);

$t = new_ok('Test::Applify', ['./scripts/key-db', 'delete']);

my $db = create_db(Mojo::File->new($0)->basename);
my @opt = (qw{-command /sbin/nologin -key-dir}, $db->to_string);

#
# delete foo's keys
#
$app = $t->app_instance(@opt, qw{-user foo});

is $app->key_files->size, 2, 'two files';

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';
is $retval, 0, 'ran ok';
like $stdout, qr/^deleting:/, 'message';
is $stderr, '', 'no messages';

is $app->key_files->size, 1, 'one file';

#
# delete bar's keys
#
$app = $t->app_instance(@opt, qw{-user bar});

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';
is $retval, 0, 'ran ok';
like $stdout, qr/^deleting:/, 'message';
is $stderr, '', 'no messages';

is $app->key_files->size, 0, 'no files';

#
# new database
#

$db = create_db(Mojo::File->new($0)->basename);
@opt = (qw{-command /sbin/nologin -key-dir}, $db->to_string);


#
# delete by key
#
$app = $t->app_instance(@opt, qw{-public-key ./t/data/user2.ps.authorized_keys});

is $app->key_files->size, 2, 'two files';

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';
is $retval, 0, 'ran ok';
like $stdout, qr/^deleting:/, 'message';
is $stderr, '', 'no messages';

is $app->key_files->size, 1, 'one file';

#
# new database
#

$db = create_db(Mojo::File->new($0)->basename);
@opt = (qw{-command /sbin/nologin -key-dir}, $db->to_string);

#
# delete by key and user
#
$app = $t->app_instance(@opt, qw{-public-key ./t/data/user2.ps.authorized_keys -user foo});

is $app->key_files->size, 2, 'two files';

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';
is $retval, 0, 'ran ok';
is +($stdout =~ s/^(deleting:)/$1/gm), 2, 'message';
is $stderr, '', 'no messages';

is $app->key_files->size, 0, 'no files';


#
# new database
#
$db = create_db(Mojo::File->new($0)->basename);
@opt = (qw{-command /sbin/nologin -key-dir}, $db->to_string);

#
# delete by key and user bar owns user2 key - checking unique results in code
# and no error messages.
#
$app = $t->app_instance(@opt, qw{-public-key ./t/data/user2.ps.authorized_keys -user bar});

is $app->key_files->size, 2, 'two files';

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);

is $exited, 0, 'ran ok';
is $retval, 0, 'ran ok';
is +($stdout =~ s/^(deleting:)/$1/gm), 1, 'message';
is $stderr, '', 'no messages';

is $app->key_files->size, 1, 'no files';



done_testing();
