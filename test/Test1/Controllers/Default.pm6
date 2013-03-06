use v6;
use Web::App::MVC::Controller;
use Test1::Model;

class Test1::Controllers::Default is Web::App::MVC::Controller 
{
  method handle ($context) 
  {
    #$*ERR.say: "in handle()";
    $context.content-type: 'text/plain';
    my $name = $context.get('name', :default<World>);
    my $model = self.get-model(Test1::Model);
    my $users = $model.get.rows;
    $context.send: self.render('hello', :$name, :$users);
  }
}

