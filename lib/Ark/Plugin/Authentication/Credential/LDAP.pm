package Ark::Plugin::Authentication::Credential::LDAP;
use Ark::Plugin 'Auth';

has ldap_uid_field => (
   is       => 'rw',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      my $self = shift;
      $self->class_config->{ldap_uid_field} || 'uid';
   },
);

has ldap_pass_field => (
   is       => 'rw',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      my $self = shift;
      $self->class_config->{ldap_pass_field} || 'pass';
   },
);

has host => (
   is       => 'rw',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      my $self = shift;
      $self->class_config->{host} || '127.0.0.1';
   },
);

has base => (
   is       => 'rw',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      my $self = shift;
      $self->class_config->{base};
   },
);

has group => (
   is       => 'rw',
   isa      => 'Str',
   lazy     => 1,
   default  => sub {
      my $self = shift;
      $self->class_config->{group} || '';
   },
);

around authenticate => sub {
    my $prev = shift->(@_);
    return $prev if $prev;

    my ($self, $info) = @_;

    my $c = $self->context;

    my $id   = $c->req->parameters->{$self->ldap_uid_field};
    my $pass = $c->req->parameters->{$self->ldap_pass_field};

    return unless ($id or $pass);

    $self->ensure_class_loaded('Net::LDAP');


    if($self->group){
        my $ldap = Net::LDAP->new($self->host) || return;
        $ldap->bind;
        my $mesg = $ldap->search(
            base   => $self->group,
            filter => "(memberUid=$id)",
        );
        $ldap->unbind;
        return if($mesg->count() <= 0);
    }
    
    my $ldap = Net::LDAP->new($self->host) || return;
    my $mesg = $ldap->bind("uid=$id,".$self->base, password => $pass);
    $ldap->unbind;
    
    if(!$mesg->code){
        my $user_obj = $self->find_user($id, {id => $id, pass => $pass});
        if ($user_obj) {
            $self->persist_user($user_obj);
            warn "ldap login";
            return $user_obj;
        }
    }
    warn "ldap not login...";
    return;
};

1;
