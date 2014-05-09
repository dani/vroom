package Mojolicious::Plugin::Mailer;
use Mojo::Base 'Mojolicious::Plugin';

use strict;
use warnings;

use Email::MIME;
use Email::Sender::Simple;
use Email::Sender::Transport::Test;
use Encode;
use utf8;

our $VERSION = '0.05';


sub register {
  my ($self, $app, $conf) = @_;

  $app->helper(
    email => sub {
      my $self = shift;
      my $args = @_ ? { @_ } : return;


      my @data  = @{ $args->{data} };

      my @parts = (
        Email::MIME->create(
          body => Encode::encode('UTF-8', $self->render(
            @data,
            format => $args->{format} ? $args->{format} : 'email_html',
            partial => 1
          )),
          attributes => {
            charset      => 'utf-8',
            content_type => 'text/html',
          }
        ),
        Email::MIME->create(
          body => Encode::encode('UTF-8', $self->render(
            @data,
            format => $args->{format} ? $args->{format} : 'email_text',
            partial => 1
          )),
          attributes => {
            charset      => 'utf-8',
            content_type => 'text/plain',
          }
        ),
      );

      my $transport = defined $args->{transport} || $conf->{transport}
                            ? $args->{transport} || $conf->{transport}
                            : undef;

      my $header = { @{ $args->{header} } };

      $header->{From}    ||= $conf->{from};
      $header->{Subject} ||= $self->stash('title');

      my $email = Email::MIME->create(
        header => [ %{$header} ],
        parts  => [ @parts ]
      );

      $email->charset_set     ( $args->{charset}      ? $args->{charset}      : 'utf-8'     );
      $email->content_type_set( $args->{content_type} ? $args->{content_type} : 'text/html' );

      return Email::Sender::Simple->try_to_send( $email, { transport => $transport } ) if $transport;

      my $emailer = Email::Sender::Transport::Test->new;
      $emailer->send_email(
                  $email,
                  {
                    to   => [ $header->{To} ],
                    from =>   $header->{From}
                  }
                );
      return unless $emailer->{deliveries}->[0]->{successes}->[0];

    }
  );

}

1;

__END__
