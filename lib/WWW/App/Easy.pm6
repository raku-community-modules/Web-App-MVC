use WWW::App::Dispatch;

class WWW::App::Easy is WWW::App::Dispatch;

use JSON::Tiny;

has %.config;    ## Our main configuration.
has %!configs;   ## On-demand loaded configurations.
has %!sessions;  ## A list of in-memory client sessions.
has %!handlers;  ## Cached handler/controller objects.
has %!models;    ## Cached model objects.

## Overrides the new() from WWW::App, with support for a :config option.
method new (*%opts) {
  my %config;
  my $engine;
  if %opts.exists('config') {
    %config = from-json(slurp(%opts<config>));
  }
  if %opts.exists('connector') {
    $engine = %opts<connector>;
  }
  elsif %config.exists('connector') {
    my $cx = %config<connector>;
    if ! $cx.exists('type') { die "no type specified in connector configuration" }
    my $type = $cx<type>;
    my %copts = {};
    for $cx.keys -> $cxopt {
      if $cxopt ne 'type' {
        %copts{$cxopt} = $cx{$cxopt};
      }
    }
    given $type.lc {
      when 'scgi' {
        %copts<PSGI> = True;
        require SCGI;
        $engine = ::('SCGI').new(|%copts);
      }
      when /f[ast]?cgi/
      {
        %copts<PSGI> = True;
        require FastCGI;
        $engine = ::('FastCGI').new(|%copts);
      }
      when /easy/ {
        require HTTP::Easy::PSGI;
        $engine = ::('HTTP::Easy::PSGI').new(|%copts);
      }
      when /simple/ {
        require HTTP::Server::Simple::PSGI;
        my $port = %copts<port> // 8080;
        $engine = ::('HTTP::Server::Simple::PSGI').new($port);
      }
      default {
        die "unknown or unsupported connector type";
      }
    }
  }
  else {
    die "no connector specified";
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
    return %!configs{$name};
  }
  else {
    return self.load-config($name);
  }
}

## Get a setting from our main config file.
method get ($name) {
  if %!config.exists($name) {
    return %!config{$name};
  }
  return Nil;
}

## Overriding the process-handler method to handle type objects and strings.
method process-handler ($handler, $context) {
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
  elsif $handler ~~ Str {
    my $controller;
    if %!handlers.exists{$handler} {
      $controller = %!handlers{$handler};
    }
    else {
      require $handler;
      $controller = ::($handler).new(:app(self));
      %!handlers{$handler} = $controller;
    }
    return $controller.handle($context);
  }
  else {
    nextsame; ## If we're not a type object, or Str, go back to the orignal process-handler().
  }
}

## Get a model object.
method get-model ($model) {
  my $object;
  my $confs = self.get-config('models');
  my $conf = {};
  if $model.defined {
    if $model ~~ Str {
      ## If you pass a string, we consider it to be the class name.
      if (%!models.exists($model)) {
        return %!models{$model};
      }
      if $confs.exists($model) {
        $conf = $confs{$model};
      }
      require $model;
      $conf<app> = self;
      $object = ::($model).new(|$conf);
      %!models{$model} = $object;
    }
    else {
      ## No idea what you passed, returning it as is.
      return $model;
    }
  }
  elsif $model ~~ Any {
    ## We're assuming a type object.
    my $typename = $model.WHAT.perl;
    if %!models.exists($typename) {
      return %!models{$typename};
    }
    if $confs.exists($typename) {
      $conf = $confs{$typename};
    }
    $conf<app> = self;
    $object = $model.new(|$conf);
    %!models{$typename} = $object;
  }
  else {
    die "unknown model, '$model', specified in get-model()";
  }
  return $object;
}

