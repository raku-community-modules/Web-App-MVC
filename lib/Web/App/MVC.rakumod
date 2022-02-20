use Web::App::Dispatch;

unit class Web::App::MVC is Web::App::Dispatch;

use JSON::Tiny;

has %.config;    ## Our main configuration.
has %!configs;   ## On-demand loaded configurations.
has %!sessions;  ## A list of in-memory client sessions.
has %!handlers;  ## Cached handler/controller objects.
has %!models;    ## Cached model objects.

## Overrides the new() from Web::App, with support for a :config option.
method new(*%opts) {
    my %config;
    my $engine;
    if %opts<config>:exists {
        %config = from-json(slurp(%opts<config>));
    }
    if %opts<connector>:exists {
        $engine = %opts<connector>;
    }
    elsif %config<connector>:exists {
        my %cx = %config<connector>;
        if not %cx<type>:exists { die "no type specified in connector configuration" }
        my $type = %cx<type>;
        my %copts := {};
        for %cx.keys -> $cxopt {
            if $cxopt ne 'type' {
                %copts{$cxopt} = %cx{$cxopt}; 
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
    self.bless(:$engine, :%config)
}

## Load an on-demand configuration.
method load-config($name) {
    my $filename;
    if %!config.exists($name) {
        $filename = %!config{$name};
    }
    elsif $name.IO.f {
        $filename = $name;
    }
    else {
        die "no such config section: '$name'";
    }
    %!configs{$name} = from-json(slurp($filename));
}

## Get an on-demand config section.
method get-config($name) {
    %!configs.exists($name)
      ?? %!configs{$name}
      !! self.load-config($name)
}

## Get a setting from our main config file.
method get($name) {
    %!config.exists($name)
      ?? %!config{$name}
      !! Nil
}

## Overriding the process-handler method to handle type objects and strings.
method process-handler($handler, $context) {
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
        $controller.handle($context)
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
        $controller.handle($context)
    }
    else {
        nextsame; ## If we're not a type object, or Str, go back to the orignal process-handler().
    }
}

method extract-config-path($hash, *@paths) {
    my $current = $hash;
    for @paths -> $path {
        if $current ~~ Hash && $current.exists($path) {
            $current = $current{$path};
        }
        else {
            $current = Nil;
            last;
        }
    }
    if $current ~~ Hash && $current.exists('.include') {
        my $include = $current<.include>;
        my @incpath = $include.split('.');
        my $cname = @incpath.shift;
        my $config = self.get-config($cname);
        my $conf = self.extract-config-path($config, |@incpath);
        if $conf ~~ Hash {
            $current = ( @$current, @$conf ).flat;
        }
    }
    $current
}

## Get model options.
method !get-model-opts($modelname) {
    my $models = self.get-config('models');
    my $opts = self.extract-config-path($models, $modelname) // {};
    $opts<caller> = self;
    $opts
}

## Get a model object.
method get-model($model) {
    my $object;
    if $model.defined {
        if $model ~~ Str {
            ## If you pass a string, we consider it to be the class name.
            if (%!models.exists($model)) {
                return %!models{$model};
            }
            my $conf = self!get-model-opts($model);
            require $model;
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
        my $conf = self!get-model-opts($typename);
        $object = $model.new(|$conf);
        %!models{$typename} = $object;
    }
    else {
        die "unknown model, '$model', specified in get-model()";
    }
    $object
}

# vim: expandtab shiftwidth=4
