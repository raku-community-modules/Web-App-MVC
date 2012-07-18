use WWW::App;

class WWW::App::Easy is WWW::App;

use JSON::Tiny;

has %!config;    ## Our main configuration.
has %!configs;   ## On-demand loaded configurations.
has %!sessions;  ## A list of in-memory client sessions.
has %!handlers;  ## Pre-loaded handlers. Woot.

## Overrides the new() from WWW::App, with support for a :config option.
method new ($engine, *%opts) {
  my %config;
  if %opts.exists('config') {
    %config = from-json(slurp(%opts<config>));
  }
  return self.bless(*, :$engine, :%config);
}

## Load an on-demand configuration.
method load-config ($name) {
  my $filename;
  if %!config.exists($name) {
    $filename = %!config{$name};
  }
  elsif $name.IO ~~ :f {
    $filename = $name;
  }
  else {
    die "no such config section: '$name'";
  }
  %!configs{$name} = from-json(slurp($filename));
}

## Get an on-demand config section.
method get-config ($name) {
  if %!configs.exists($name) {
    return %!config{$name};
  }
  else {
    return self.load-config($name);
  }
}

## Overriding the !process-handler method to handle type objects.
method !process-handler ($handler, $context) {
  if ((! $handler.defined) && $handler ~~ Any) {
    my $controller;
    my $typename = $handler.WHAT.perl;
    if %!handlers.exists($typename) {
      $controller = %!handlers{$typename};
    }
    else {
      $controller = $handler.new(:app(self));
      %!handlers{$typename} = $controller;
    }
    return $controller.handle($context);
  }
  else {
    nextsame; ## If we're not a type object, go back to the orignal process-handler().
  }
}


