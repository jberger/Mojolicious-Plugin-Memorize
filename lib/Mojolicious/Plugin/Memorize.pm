package Mojolicious::Plugin::Memorize;

use Mojo::Base 'Mojolicious::Plugin';
our $VERSION = '0.01';
$VERSION = eval $VERSION;

has cache => sub { +{} };

sub register {
  my ($plugin, $app) = @_;

  $app->helper(
    memorize => sub {
      my $c = shift;
      return $plugin unless @_;
      unshift @_, $plugin;
      goto $plugin->can('memorize'); # for the sake of the auto-naming
    }
  );

}

sub expire {
  my ($self, $name) = @_;
  $self->cache->{$name}{expires} = 1;
}

sub memorize {
  my $self = shift;
  my $mem = $self->cache;

  return '' unless ref(my $cb = pop) eq 'CODE';
  my ($name, $args)
    = ref $_[0] eq 'HASH' ? (undef, shift) : (shift, shift || {});

  # Default name
  $name ||= join '', map { $_ || '' } (caller(1))[0 .. 3];

  # Expire old results
  my $expires;
  if (exists $mem->{$name}) {
    $expires = $mem->{$name}{expires};
    delete $mem->{$name}
      if $expires > 0 && $mem->{$name}{expires} < time;
  } else {
    $expires = $args->{expires} || 0;
  }

  # Memorized result
  return $mem->{$name}{content} if exists $mem->{$name};

  # Memorize new result
  $mem->{$name}{expires} = $expires;
  return $mem->{$name}{content} = $cb->();
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
   $self->memorize->expire('access');
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

The C<memorize> helper derives from the helper that was removed from C<Mojolicious> at version 4.0, with one tiny addition, the underlying plugin object is returned when no arguments are passed. This makes more flexible interaction possible, including, as an example, the C<expire> method.

=head1 HELPERS

=over

=item C<memorize( [$name,] [$args,] [$template_block] )>

When called with arguments, the helper behaves as the old helper did. It takes as many as three arguments, the final of which must be a template block (begin/end, see L<Mojolicious::Lite/Blocks>) to be memorized. The first argument may be a string which is the name (key) of the memorized template (used for later access), if this is not provided one will be generated. A hashref may also be passed in which is used for additional arguments; as of this writing, the only available argument is C<expires>. If C<expires> is greater than zero and less than the current C<time> then the template block is re-evaluated. In this case the return value is the memorized template result.

When called without arguments, the plugin object is returned, allowing the use of other plugin methods or access to the plugin's cache.

=back

=head1 ATTRIBUTES

=over

=item C<cache>

A hash reference containing the memorized template content and other data. 

=back

=head1 METHODS

=over

=item C<expire( $name )>

This method allows for manually expiring a memorized template block. This may useful if the template is set to never expire or when the underlying content is known to have changed.

This is an example of the utility of having access to the underlying hash. In the original implementation of the core helper, this access was not available.

=item C<register>

This method is called upon loading the plugin and probably is not useful for other purposes.

=back

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


=head1 AUTHORS

=over

=item Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=item Sebastian Riedel 

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joel Berger and Sebastian Riedel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

