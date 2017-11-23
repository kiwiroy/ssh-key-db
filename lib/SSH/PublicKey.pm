package SSH::PublicKey;

use Mojo::Base -base;
use Mojo::Template;
use Mojo::Util 'trim';

our $VERSION = '0.01';

my @key_types = qw{
ecdsa-sha2-nistp256
ecdsa-sha2-nistp384
ecdsa-sha2-nistp521
ssh-ed25519
ssh-dss
ssh-rsa
};

has command => sub {
    my $self = shift;
    (my $r = $self->_restrictions || '') =~ s/command=\"([^"]+)\".*/$1/;
    trim $r;
};

has [qw{comment key type val}];

has no_pty => sub {
    _parse_restriction_flag(shift->_restrictions, qr/no\-pty/);
};
has no_port_forwarding => sub {
    _parse_restriction_flag(shift->_restrictions, qr/no\-port\-forwarding/);
};
has no_X11_forwarding => sub {
    _parse_restriction_flag(shift->_restrictions, qr/no\-X11\-forwarding/);
};
has no_agent_forwarding => sub {
    _parse_restriction_flag(shift->_restrictions, qr/no\-agent\-forwarding/);
};

sub new { shift->SUPER::new(@_)->_parse; }

sub render {
    my ($self, @parts, $r) = (shift);

    push @parts, $r if ($r = $self->restrictions);
    push @parts, $self->type;
    push @parts, $self->key;
    push @parts, $self->comment if $self->comment;

    return "@parts\n";
}

sub restrictions {
    my ($self, @parts) = (shift);
    push @parts, sprintf('command="%s"', $self->command) if $self->command;
    push @parts, (map { $self->$_ ? $self->_attr_to_option($_) : () }
                  qw{no_pty no_port_forwarding no_X11_forwarding no_agent_forwarding});
    return join ',' => @parts;
}

sub _attr_to_option {
    local $_ = $_[1] or return;
    s!_!-!g;
    $_;
}

sub _parse {
    my $self = shift;
    return $self unless $self->{val};
    my $RE = $self->_parse_re;
    if ($self->{val} =~ m/$RE/) {
        $self->_restrictions($1)->type($2)->key($3)->comment($4);
        chop($self->{_restrictions}) if $1;
    } else {
        say STDERR "Failed to parse: ", $self->{val};
    }
    return $self;
}

has _parse_re => sub {
    my $types = join '|', @key_types;
    return qr{^(.*)\s?($types)\s([^\s]+)\s?(.*)$};
};

sub _parse_restriction_flag {
    my ($restrictions, $re) = @_;
    $restrictions =~ m/$re/ ? 1 : 0;
}

has '_restrictions';

1;

=pod

=head1 NAME

SSH::PublicKey - A ssh public key object

=head1 DESCRIPTION

An object that can represent a ssh public key.

=head1 SYNOPSIS

=head1 METHODS

=head2 command

=head2 comment

=head2 key

=head2 new

=head2 render

=head2 restrictions

=head2 type

=head2 val

=cut
