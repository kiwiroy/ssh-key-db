## -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Test::Applify;

my $t;

$t = new_ok('Test::Applify', ['./scripts/key-db']);
$t->help_ok
    ->documentation_ok
    ->is_option('key_dir')
    ->can_ok('key_files')
    ->can_ok(qw{command_add command_list command_update command_delete});

is_deeply $t->app_instance(qw{-key-dir ./t/data})->key_files,
    [ qw{t/data/user1.shutdown.authorized_keys t/data/user2.ps.authorized_keys} ], 
    'test data files';

$t = new_ok('Test::Applify', ['./scripts/key-db', 'add']);
$t->help_ok
    ->documentation_ok
    ->is_option('key_dir')
    ->is_option('unique')
    ->is_required_option('command')
    ->is_required_option('public_key')
    ->is_required_option('username')
    ->is_required_option('allowed')
    ->is_required_option('reason');

is $t->app_instance(qw{-command none})->command, 'none', 'test data files';

is $t->app_instance(qw{-public-key ./t/data/user1.shutdown.authorized_keys})->public_key,
    './t/data/user1.shutdown.authorized_keys', 'sets correctly';

$t = new_ok('Test::Applify', ['./scripts/key-db', 'list']);
$t->help_ok
    ->documentation_ok
    ->is_option('key_dir')
#    ->is_required_option('command')
    ->is_option('public_key')
    ->is_option('username');

$t = new_ok('Test::Applify', ['./scripts/key-db', 'update']);
$t->help_ok
    ->documentation_ok
    ->is_option('key_dir')
    ->is_option('command')
    ->is_option('allowed')
    ->is_required_option('public_key');

is $t->app_instance(qw{-command none})->command, 'none', 'test data files';

$t = new_ok('Test::Applify', ['./scripts/key-db', 'delete']);
$t->help_ok
    ->documentation_ok
    ->is_option('key_dir')
#    ->is_required_option('command')
    ->is_option('public_key')
    ->is_option('username');



done_testing();