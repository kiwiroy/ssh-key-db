## -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use SSH::PublicKey;

my $key = new_ok('SSH::PublicKey');

$key = new_ok('SSH::PublicKey', [val => 'ssh-rsa AAAAAAAAAAAAAAAAA=']);
is $key->type, 'ssh-rsa', 'key type correct';
is $key->key, 'AAAAAAAAAAAAAAAAA=', 'key key correct';
is $key->render, "ssh-rsa AAAAAAAAAAAAAAAAA=\n", 'round trip';

$key = new_ok('SSH::PublicKey', [val => 'ssh-rsa AAAAAAAAAAAAAAAAA= comment']);
is $key->type, 'ssh-rsa', 'key type correct';
is $key->key, 'AAAAAAAAAAAAAAAAA=', 'key key correct';
is $key->comment, 'comment', 'key comment correct';
is $key->render, "ssh-rsa AAAAAAAAAAAAAAAAA= comment\n", 'round trip';

for (qw{ecdsa-sha2-nistp256
ecdsa-sha2-nistp384
ecdsa-sha2-nistp521
ssh-ed25519
ssh-dss
ssh-rsa
}) {
    $key = new_ok('SSH::PublicKey',
                  [val => "$_ AAAAAAAAAAAAAAAAA= useful comment"]);
    is $key->type, $_, 'key type correct';
    is $key->render, "$_ AAAAAAAAAAAAAAAAA= useful comment\n", 'minimum string';
}

$key = SSH::PublicKey->new(val => 'ssh-psa AAAAAAAAAEAEAE000=');
is $key->key, undef, 'no parse';

$key = SSH::PublicKey->new(val => 'command="/usr/bin/only option" ssh-rsa AAAAAAAAAEAEAE000=');
is $key->key, 'AAAAAAAAAEAEAE000=', 'key parsed';
is $key->type, 'ssh-rsa', 'type parsed';
is $key->command, '/usr/bin/only option', 'command parsed';
is $key->render, qq{command="/usr/bin/only option" ssh-rsa AAAAAAAAAEAEAE000=\n}, 'round trip';
$key->no_pty(1)->no_X11_forwarding(1);
is $key->render, qq{command="/usr/bin/only option",no-pty,no-X11-forwarding ssh-rsa AAAAAAAAAEAEAE000=\n},
    'restricted';

is $key->no_port_forwarding(1)->no_agent_forwarding(1)->render,
    qq{command="/usr/bin/only option",} .
    qq{no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAAAAAAEAEAE000=\n},
    'more restricted';

done_testing();
