use v6;
use WWW::App::Easy::Controller;
use Test1::Model;

class Test1::Controller is WWW::App::Easy::Controller {
  method handle ($context) {
    $context.content-type: 'text/plain';
    my $name = $context.get('name', :default<World>);
    my $model = self.get-model(Test1::Model);
    my $users = $model.get.rows;
    $context.send: self.render('hello', :$name, :$users);
  }
}

