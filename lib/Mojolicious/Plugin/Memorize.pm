package Mojolicious::Plugin::Memorize;

use Mojo::Base 'Mojolicious::Plugin';
our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub register {
  my ($plugin, $app) = @_;

  my %mem;
  $app->helper(
    memorize => sub {
      shift;
      return \%mem unless @_;

      return '' unless ref(my $cb = pop) eq 'CODE';
      my ($name, $args)
        = ref $_[0] eq 'HASH' ? (undef, shift) : (shift, shift || {});

      # Default name
      $name ||= join '', map { $_ || '' } (caller(1))[0 .. 3];

      # Expire old results
      my $expires;
      if (exists $mem{$name}) {
        $expires = $mem{$name}{expires};
        delete $mem{$name}
          if $expires > 0 && $mem{$name}{expires} < time;
      } else {
        $expires = $args->{expires} || 0;
      }

      # Memorized result
      return $mem{$name}{content} if exists $mem{$name};

      # Memorize new result
      $mem{$name}{expires} = $expires;
      return $mem{$name}{content} = $cb->();
    }
  );

  $app->helper( memorize_expire => sub {
    my ($self, $name) = @_;
    $self->memorize->{$name}{expires} = 1;
  });
}

1;

=head1 NAME

Mojolicious::Plugin::Memorize - Memorize part of your Mojolicious template

=head1 SYNOPSIS

 use Mojolicious::Lite;
 plugin 'Memorize';

 any '/' => 'index';

 any '/reset' => sub {
   my $self = shift;
   $self->memorize_expires('access');
   $self->redirect_to('/');
 };

 app->start;

 __DATA__

 @@ index.html.ep

 %= memorize access => { expires => 0 } => begin
   This page was memorized on 
   %= scalar localtime
 % end

=head1 DESCRIPTION

This plugin provides the functionality to easily memorize a portion of a template, to prevent re-evaluation. This may be useful when a portion of your response is expensive to generate but changes rarely (a menu for example).

The C<memorize> helper derives from the helper that was removed from C<Mojolicious> at version 4.0, with one tiny addition, the underlying storage hash is returned when no arguments are passed. This makes more flexible interaction possible, an example of which is the new C<memorize_expire> helper.

=head1 HELPERS

=head2 C<memorize( [$name,] [$args,] $template_block )>

Takes as many as three arguments. To be used noramlly, the final argument must be a template block (begin/end, see L<Mojolicious::Lite/Blocks>) to be memorized. The first argument may be a string which is the name (key) of the memorized template (used for later access), if this is not provided one will be generated. A hashref may also be passed in which is used for additional arguments; as of this writing, the only available argument is C<expires>. If C<expires> is greater than zero and less than the current C<time> then the template block is re-evaluated.

When called with arguments, the return value is either the memorized template result. When called without arguments, a reference to the hash of memorized templates is returned.

=head2 C<memorize_expire( $name )>

This helper allows for manually expiring a memorized template block. For example, this may be called when the template is set to never expire or when the underlying content is known to have changed.

This is an example of the utility of having access to the underlying hash. In the original implementation of the core helper, this access was not available.

=head1 SEE ALSO

=over

=item *

L<Mojolicious>

=item *

L<Mojolicious::Plugin>

=item *

L<Mojolicious::Guides::Rendering>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-Memorize> 


=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

