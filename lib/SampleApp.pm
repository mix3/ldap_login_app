package SampleApp;
use Ark;

our $VERSION = '0.01';

use_plugins qw{
    Session
    Session::State::Cookie
    Session::Store::Model

    Authentication
    Authentication::Credential::LDAP
    Authentication::Store::Null
};

config 'Plugin::Session' => {
    expires => '+30d',
};

config 'Plugin::Session::State::Cookie' => {
    cookie_name => 'sample_app_session',
};

config 'Plugin::Session::Store::Model' => {
    model => 'cache',
};

config 'Plugin::Authentication::Credential::LDAP' => {
    base  => 'ou=People,dc=mix3,dc=org',
    group => 'cn=sample,ou=Project,dc=mix3,dc=org',
};

use_model 'SampleApp::Models';
my $home = SampleApp::Models->get('home');

# MT
config 'View::Tiffany' => {
    view => 'Text::MicroTemplate::Extended',
    options => {
        include_path => [ $home->subdir('root', 'tmpl') ],
        template_args => {
            c => sub{ __PACKAGE__->context },
            s => sub{ __PACKAGE__->context->stash },
        },
    },
};

1;
