use Web::App::MVC::Controller;
use Web::App::MVC::Controller::MethodDispatch;

class Test1::Controllers::Dispatch 
  is Web::App::MVC::Controller 
  does Web::App::MVC::Controller::MethodDispatch
{
    method handle_echo ($context, *@paths) {
        $context.content-type: 'text/plain';
        my $output; 
        if @paths.elems {
            $output = @paths.join("\n");
        }
        else {
            $output = "Nothing to see, try adding paths.";
        }
        $context.send: "$output\n";
        True
    }
    method handle_hello ($context, $name='World', *@paths) {
        $context.content-type: 'text/plain';
        $context.send: "Hello $name\n";
        True
    }
}

# vim: expandtab shiftwidth=4
