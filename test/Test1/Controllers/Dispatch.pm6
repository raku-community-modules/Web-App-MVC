use v6;
use WWW::App::Easy::Controller;
use WWW::App::Easy::Controller::MethodDispatch;

class Test1::Controllers::Dispatch 
      is WWW::App::Easy::Controller 
    does WWW::App::Easy::Controller::MethodDispatch
{
  method handle_echo ($context, *@paths)
  {
    $context.content-type: 'text/plain';
    my $output; 
    if @paths.elems
    {
      $output = @paths.join("\n");
    }
    else
    {
      $output = "Nothing to see, try adding paths.";
    }
    $context.send: "$output\n";
    return True;
  }
  method handle_hello ($context, $name='World', *@paths)
  {
    $context.content-type: 'text/plain';
    $context.send: "Hello $name\n";
    return True;
  }
}

