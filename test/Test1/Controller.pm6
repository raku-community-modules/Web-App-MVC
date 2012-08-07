use v6;
use WWW::App::Easy::Controller;

class Test1::Controller is WWW::App::Easy::Controller {
  method handle ($context) {
    $context.content-type: 'text/plain';
    my $name = $context.get('name', :default<World>);
    $context.send: self.render('hello', :$name);
  }
}
