# Web::App::MVC [![Build Status](https://travis-ci.org/tbrownaw/perl6-web-app-mvc.svg?branch=master)](https://travis-ci.org/tbrownaw/perl6-web-app-mvc)

## Introduction

A set of extensions to [Web::App](https://github.com/supernovus/perl6-web/) 
providing a MVC-style framework for building dynamic web applications.

We include a few base classes and roles, for quickly defining Controllers, 
capable of loading one or more Models (with built-in support for models based
on the [DB::Model::Easy](https://github.com/supernovus/perl6-db-model-easy/) library) and displaying one or more Views.

## Example Application Script

```perl
    use Web::App::MVC;
    use My::Controller;

    my $app  = Web::App::MVC.new(:config<./conf/app.json>);

    $app.add(:handler(My::Controller));

    $app.run;
```

## Example Configuration Files

### ./conf/app.json

```json
    {
      "connector"   : {
        "type"      : "SCGI",
        "port"      : 8118
      },
      "views"       : {
        "type"      : "Template6",        
        "dir"       : "./templates"
      },
      "db"          : "./conf/db.json",
      "models"      : "./conf/models.json"
    }
```

### ./conf/models.json

```json
    {
      "My::Models::Example" : {
        ".include" : "db.defaultdb",
        "table"    : "mytable"
      }
    }
```

### ./conf/db.json

```json
    {
      "defaultdb" : {
        "driver" : "mysql",
        "opts"   : {
          "host"     : "localhost",
          "port"     : 3306,
          "database" : "myappdb",
          "user"     : "myappuser",
          "password" : "myapppass"
        }
      }
    }
```

## Example Controller Library

```perl
    use Web::App::MVC::Controller;
    use My::Models::Example;
    class My::Controller is Web::App::MVC::Controller {
      method handle ($context) {
        $context.content-type: 'text/html';
        my $id = $context.get('id', :default(1));

        my $model = self.get-model(My::Models::Example);
        my $user = $model.getUserById($id);
        my $name = $user.name;

        my $jobusers = $model.get.with(:job($user.job)).and.not(:id($user.id)).rows;

        $context.send: self.render('default', :$name, :$jobusers);
      }
    }
```

## Example Model Library

```perl
    use DB::Model::Easy;
    class My::Models::Example::User is DB::Model::Easy::Row {
      has $.id;
      has $.name is rw;
      has $.age  is rw;
      has $.job  is rw;

      ## Rules for mapping database columns to object attributes.
      ## 'id' is a primary key, auto-generated. The column for 'job' is called 'position'.
      has @.fields = 'id' => {:primary, :auto}, 'name', 'age', 'job' => 'position';
    }
    class My::Models::Example is DB::Model::Easy {
      has $.rowclass = My::Models::Example::User;
      method getUserById ($id) {
        self.get.with(:id($id)).row;
      }
    }
```

## Example View Template

```html
    <html>
      <head>
        <title>Hello [% name %]</title>
      </head>
      <body>
        <h1>Other users with the same job as you</h1>
        <table>
          <tr>
            <th>Name</th>
            <th>Age</th>
          </tr>
          [% for jobusers as user %]
          <tr>
            <th>[% user.name %]</th>
            <th>[% user.age %]</th>
          </tr>
          [% end %]
        </table>
      </body>
    </html>
```

## More examples

See the included examples in the 'test' folder for even more examples,
including the use of the Web::App::Controller::MethodDispatch role.

##  Configuration File Directives

The main application configuration file, specifies certain settings that will
be used in various places in your application. You can add as many additional
settings and config files as you want for your own needs, 
below is a list of known and/or required settings.

#### connector

Required by Web::App::MVC, this hash specifies which connector engine to 
use to handle your application. 
We support the same connectors as Web::App itself. The __type__ key
determines the name of the library to use, and all other options will be 
passed to the respective libraries. 
At this time, the only other option supported (and indeed required)
by the libraries, is the __port__ option, which determines which port the 
connector will run on. 

The types may be specified as short keys (and are case insensitive):

 * scgi -- Use the [SCGI](https://github.com/supernovus/SCGI/) connector.
 * fcgi -- Use the [FastCGI](https://github.com/supernovus/perl6-fastcgi/) connector.
 * easy -- Use the [HTTP::Easy](https://github.com/supernovus/perl6-http-easy/) connector.
 * simple -- Use the [HTTP::Server::Simple](https://github.com/mberends/http-server-simple/) connector.

#### views

If you are using the View capabilities provided with the Controller class, 
this hash directive specifies the template engine and options for it to use 
to parse your views. 

As with connector, the __type__ key specifies the name of the supported 
template engine  library you want to use, and all other parameters are 
passed to the engine.

We support any template engine that has a wrapper class available in the
[Web::Template](https://github.com/supernovus/perl6-web-template/) library.

The types may be specified as short keys (And are case insensitive):

 * 'template6' or 'tt' -- Use the [Template6](https://github.com/supernovus/template6/) engine.
 * 'tal' or 'flower' -- Use the [Flower::TAL](https://github.com/supernovus/flower/) engine.
 * 'html' -- Use the [HTML::Template](https://github.com/masak/html-template/) engine.
 * 'mojo' -- Use the [Template::Mojo](https://github.com/tadzik/Template-Mojo/) engine.

All of these engines support a __dir__ option that can be a single path,
or an array of paths, which specify the paths to find templates in.

#### models

This specifies the file name for the models configuration file.

If you are using the get-model() method of the Controller class, 
and there is a key in the models configuration that matches the class name 
of your model, then the hash entries within will be passed as named 
options to your model class. 

There are no standards for this, unless you are using the 
DB::Model::Easy base class, in which case you must supply 
a __table__ parameter here. You may also specify __driver__ and __opts__ 
parameters here, but they are best stored in a separate configuration file,
which can be included here using a __.include__ parameter (see below.)

#### db

This specifies the file name for the database configuration file.

If you are using the DB::Model::Easy base class, then it needs to know
the connection details for databases. This file should exist to contain the
configuration details.

You can refer to these database configurations from the model configuration, 
using a special __.include__ parameter which uses a limited JSON Path syntax.

The __driver__ and __opts__ parameters will determine the db connection.

Supported __drivers__ are whatever DBIish supports. Currently this is:

  * mysql
  * Pg
  * SQLite

The __opts__ parameters differ from one driver to the next. 
See the [DBIish documentation](https://github.com/perl6/DBIish/) 
for more details.

## Author

Timothy Totten. Catch me on #perl6 as 'supernovus'.

## License

Artistic License 2.0

