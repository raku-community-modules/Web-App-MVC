# WWW::App::Easy

## Introduction

A set of extensions to [WWW::App](https://github.com/supernovus/www-app/) providing a MVC-style 
framework for building dynamic web applications using Perl 6. 
We include a few base classes and roles, for quickly defining Controllers, 
capable of loading one or more Models (with an included base class for DB models), 
and displaying one or more Views (which by default are using the Template6 template engine.)

## Example Application Script

```perl
    use WWW::App::Easy;
    use My::Controller;

    my $app  = WWW::App::Easy.new(:config<./conf/app.json>);

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

### ./conf/models.json

```json
    {
      "My::Models::Example" : {
        "database" : "defaultdb",
        "table"    : "mytable"
      }
    }
```

## Example Controller Library

```perl
    use WWW::App::Easy::Controller;
    use My::Models::Example;
    class My::Controller is WWW::App::Easy::Controller {
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
    use WWW::App::Easy::Model::DB;
    class My::Models::Example::User is WWW::App::Easy::Model::DB::Row {
      has $.id;
      has $.name is rw;
      has $.age  is rw;
      has $.job  is rw;

      ## Rules for mapping database columns to object attributes.
      ## 'id' is a primary key, auto-generated. The column for 'job' is called 'position'.
      has @.fields = 'id' => {:primary, :auto}, 'name', 'age', 'job' => 'position';
    }
    class My::Models::Example is WWW::App::Easy::Model::DB {
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

##  Configuration File Directives

The main application configuration file, specifies certain settings that will
be used in various places in your application. You can add as many additional
settings and config files as you want for your own needs, below is a list of known
and/or required settings.

#### connector

Required by WWW::App::Easy, this hash specifies which connector engine to use to handle
your application. We support the same connectors as WWW::App itself. The __type__ key
determines the name of the library to use, and all other options will be passed to the
respective libraries. At this time, the only other option supported (and indeed required)
by the libraries, is the __port__ option, which determines which port the connector will
run on. The types may be specified as short keys (and are case insensitive):

 * scgi -- Use the SCGI connector.
 * easy -- Use the HTTP::Easy connector.
 * simple -- Use the HTTP::Server::Simple connector.

#### views

If you are using the View capabilities provided with the Controller class, this hash
directive specifies the template engine and options for it to use to parse your views. 
As with connector, the __type__ key specifies the name of the supported template engine 
library you want to use, and all other parameters are passed to the engine.

Currently, only the Template6 engine is supported, but in the future, additional template
engines will be added. The __dir__ option can be a single path, or an array of paths, to find
the view templates in.

#### models

This specifies the file name for the models configuration file.

If you are using the get-model() method of the Controller class, and there is a key in the
models configuration that matches the class name of your model, then the hash entries within 
will be passed as named options to your model class. 

There are no standards for this, unless you are using the WWW::App::Easy::Model::DB base 
class, in which case you must supply __database__ and __table__ parameters. The __database__
parameter must be the name of a defined database in the __db__ configuration (see below.)

#### db

This specifies the file name for the database configuration file.

If you are using the WWW::App::Easy::Model::DB base class, you must specify a list of
databases in the database configuration file. You can refer to these database configurations
from the model configuration, using the __database__ key. Within the specific database
configurations, the __driver__ and __opts__ parameters will determine the db connection.

Supported __drivers__ are whatever DBIish supports. Currently this is:

  * mysql
  * Pg
  * SQLite

The __opts__ parameters differ from one driver to the next. 
See the [DBIish documentation](https://github.com/perl6/DBIish/) for more details.

## TODO

Finish testing the Model related code. The current test is woefully limited.

## Author

Timothy Totten. Catch me on #perl6 as 'supernovus'.

## License

Artistic License 2.0

