use v6;

class WWW::App::Easy::Controller;

has $.app handles <get-model>;      ## WWW::App::Easy instance.
has $.views;                        ## Template engine to use for views.

submethod BUILD (:$app) 
{
  $!app = $app;
  my $views = $app.get('views');
  if $views.defined 
  {
    given $views<type>.lc 
    {
      my $dir = $views<dir> // './views';
      when 'template6' | 'tt'
      {
        require Template6;
        $!views = ::('Template6').new;
        if $dir ~~ Array 
        {
          for $dir -> $tdir 
          {
            $!views.add-path: $tdir;
          }
        }
        else 
        {
          $!views.add-path: $dir;
        }
      }
      when 'tal' | 'flower'
      {
        require Flower::TAL;
        $!views = ::('Flower::TAL').new;
        if $dir ~~ Array
        {
          for $dir -> $tdir
          {
            $!views.provider.add-path: $tdir;
          }
        }
        else
        {
          $!views.provider.add-path: $dir;
        }
      }
      default { die "unknown or unsupported template engine."; }
    }
  }
}

method render ($template, *%opts) 
{
  if ! $!views.defined { die "no template engine has been specified."; }

  if ($!views.can('process')) 
  {
    return $!views.process($template, |%opts);
  }
  elsif ($!views.can('get')) 
  {
    my $tmpl = $!views.get($template);
    if ($tmpl.can('render'))
    {
      return $tmpl.render(|%opts);
    }
  }

  die "template engine object does not have any supported API calls.";
}

method handle ($context) { ... }

