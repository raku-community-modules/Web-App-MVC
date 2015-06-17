use v6;

unit class Web::App::MVC::Controller;

has $.app handles <get-model>;      ## Web::App::MVC instance.
has $.views;                        ## Template engine to use for views.

submethod BUILD (:$app) 
{
  $!app = $app;
  my $views = $app.get('views');
  if $views.defined 
  {
    given $views<type>.lc 
    {
      when 'template6' | 'tt'
      {
        require Web::Template::Template6;
        $!views = ::('Web::Template::Template6').new;
      }
      when 'tal' | 'flower'
      {
        require Web::Template::TAL;
        $!views = ::('Web::Template::TAL').new;
      }
      when 'html'
      {
        require Web::Template::HTML;
        $!views = ::('Web::Template::HTML').new;
      }
      when 'mojo'
      {
        require Web::Template::Mojo;
        $!views = ::('Web::Template::Mojo').new;
      }
      default { die "unknown or unsupported template engine."; }
    }

    my $dir = $views<dir> // './views';
    if $dir ~~ Array
    {
      $!views.set-path(|@$dir);
    }
    else
    {
      $!views.set-path($dir);
    }
  }
}

## This became a whole lot simpler when we moved to Web::Template.
method render ($template, *%named, *@positional) 
{
  $!views.render($template, |%named, |@positional);
}

method handle ($context) { ... }

