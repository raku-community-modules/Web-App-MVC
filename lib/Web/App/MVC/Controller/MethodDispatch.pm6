use v6;

role Web::App::MVC::Controller::MethodDispatch;

## If your controller class is to be used as a default
## controller, then set the $!default to one of:
##
##  1.) A Pair, with one of the following schemas:
##
##    a.)
##      'method' => 'name_of_method'
##      'call'   => 'name_of_method'
##    Uses the named method as the handler.
##
##    b.)
##      'url'      => 'url_or_path'
##      'redirect' => 'url_or_path'
##    Redirect to the given path or URL.
##
##    c.)
##      'status' => $integer
##      'code'   => $integer
##    Set the HTTP status code to the given integer, return no body.
##
##  2.) A Str, represents a URL or path to redirect too.
##
##  3.) An Int, represents an HTTP status code, returns no body.
##
## If this remains its default value of False, we don't attempt to act as
## a default controller, and just return False so that the application can
## query the next rule to see if it handles the request.
##
has $.default = False;

method handle ($context)
{
  my @params = $context.path.split('/').grep({ $_ !~~ /^$/});
  if @params.elems
  {
    my $method = "handle_" ~ @params.shift;
    if self.can($method)
    {
      return self."$method"($context, |@params);
    }
  }
  if $.default ~~ Pair
  {
    my $action = $.default.key.lc;
    my $value  = $.default.value;
    given $action
    {
      when 'method' | 'call'
      {
        if self.can($value)
        {
          return self."$value"($context, |@params);
        }
      }
      when 'url' | 'redirect'
      {
        $context.redirect($.default.value);
        return True;
      }
      when 'status' | 'code'
      {
        $context.set-status: $value;
        return True;
      }
    }
  }
  elsif $.default ~~ Str
  {
    if self.can($.default)
    {
      return self."$.default"($context, |@params);
    }
  }
  elsif $.default ~~ Int
  {
    $context.set-status: $.default;
    return True;
  }
  return False;
}

