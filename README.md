# WWW::App::Easy

## NOTE

This is in the planning stages at the moment. I wrote WWW::App to bring simple web application
development to Perl 6. This is the next step, providing a more complete framework.

Stay tuned for actual code.

## Introduction

A set of extensions to [WWW::App](https://github.com/supernovus/www-app/) providing a MVC-style 
framework for building dynamic web applications using Perl 6. 
We include a few base classes and roles, for quickly defining Controllers, 
capable of loading one or more Models (with an included base class for DB models), 
and displaying one or more Views (which by default are using the Template6 template engine.)

## Example Application Script

```perl
    use SCGI;
    use WWW::App::Easy;
    use My::Controller;

    my $scgi = SCGI.new(:port(8118), :PSGI);
    my $app  = WWW::App::Easy.new($scgi, :config<./conf/app.json>);

    $app.add(:handler(My::Controller));

    $app.run;
```

## Example Configuration Files

### ./conf/app.json

```json
    {
      "templatedir" : "./templates",
      "dbconf"      : "./conf/db.json",
      "modelconf"   : "./conf/models.json"
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
        $context.set-status: 200;
        $context.content-type: 'text/html';
        my $id = $context.get('id', :default(1));
        my $model = self.get-model(My::Models::Example);
        my $user = $model.getUserById($id);
        my $name = $user.name;
        $context.send: self.parse-view('default', :$name);
      }
    }
```

## Example Model Library

```perl
    use WWW::App::Easy::Model::DB;
    class My::Models::Example is WWW::App::Easy::Model::DB {
      method getUserById ($id) {
        self.getRowByFields(:id($id));
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
        <h1>Hello [% name %]</h1>
      </body>
    </html>
```

## Author

Timothy Totten. Catch me on #perl6 as 'supernovus'.

## License

Artistic License 2.0
