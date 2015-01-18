package Mojolicious::Plugin::GitHub;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::GitHub - Mojolicious Plugin handling GitHub Data & OAUTH

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('GitHub');

    # Mojolicious::Lite
    plugin 'GitHub';

=head1 DESCRIPTION

L<Mojolicious::Plugin::GitHub> is a L<Mojolicious> plugin. 
It provides GitHub OAUTH authentification and simplifies acces to user public data.

More information about GitHub OAuth: 
https://developer.github.com/v3/oauth/

=cut

use strict;
use warnings;

use Data::Printer;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;

our $VERSION = '0.02';

my $GH_OAUTH_URL = 'https://github.com/login/oauth';
my $GH_REDIRECT_DEFAULT = '/';

my ($gh_client_id, $gh_client_secret, $gh_state, $gh_redirect) = (undef, undef, undef, undef);

=head1 METHODS

L<Mojolicious::Plugin::GitHub> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=cut

sub register 
{
    my ($self, $app) = @_;
    
    my $config = $app->config();
    $gh_client_id = $config->{github}->{oauth_client_id};
    $gh_client_secret = $config->{github}->{oauth_client_secret};
    $gh_state = 'random_state';
    #TODO makes it random !
    $gh_redirect = $config->{github}->{redirect} || $GH_REDIRECT_DEFAULT;
    
    # adds 2 routes for GitHub OAuth
    my $routes = $app->routes;
    $routes->get('/github/oauth/auth')
        ->to(cb => \&github_oauth_auth);
    $routes->get('/github/oauth/authcallback')
        ->to(cb => \&github_oauth_authcallback);
}

=head2 github_oauth_auth

=cut

sub github_oauth_auth
{
    my $self = shift;

    $self->redirect_to("${GH_OAUTH_URL}/authorize?"
        . "&client_id=${gh_client_id}&state=$gh_state");
}

=head2 github_oauth_authcallback

=cut

sub github_oauth_authcallback
{
    my $self = shift;

    my $code = $self->param('code');
    #TODO check state
    my $state = $self->param('state');

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->post("$GH_OAUTH_URL/access_token" => form => {
        client_id     => $gh_client_id,
        client_secret => $gh_client_secret,
        code          => $code,
        state         => $state,
        });

    foreach my $param (split(/&/, $tx->res->body))
    {
        my ($key, $value) = split(/=/, $param);
		printf "%s => %s\n", $key, $value;
        $self->session('github_access_token' => $value)
            if ($key eq 'access_token');
    }

    $tx  = $ua->get("https://api.github.com/user?access_token=" . $self->session('github_access_token'));
    #set our session variables to the stuff we got from github
    $self->session('github_user_avatar_url' => $tx->res->json('/avatar_url'));
	$self->session('github_user_login' => $tx->res->json('/login'));
	$self->session('github_user_name' => $tx->res->json('/name'));

    p $tx->res->json();

	#GET /users/:username/repos
 
	$self->redirect_to($gh_redirect);
}

1;

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Sebastien Thebert <stt@onetool.pm>

=cut
