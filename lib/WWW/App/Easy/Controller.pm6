use v6;

class WWW::App::Easy::Controller;

use Template6;

has $.app;
has $!render;

submethod BUILD (:$app) {
  $!app = $app;
  my $tdir = $app.get('templatedir');
  $!render = Template6.new;
  $!render.add-path: $tdir;
}

method render ($template, *%opts) {
  $!render.process($template, |%opts);
}
