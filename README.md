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
        $context.content-type: 'text/html';
        my $id = $context.get('id', :default(1));

        my $model = self.get-model(My::Models::Example);
        my $user = $model.getUserById($id);
        my $name = $user.name;

        my $jobusers = $model.get.with(:job($user.job)).not(:id($user.id)).rows;

        $context.send: self.view('default', :$name, :$jobusers);
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
      has @!fields = 'id' => {:primary, :auto}, 'name', 'age', 'job' => {:column<position>};
    }
    class My::Models::Example is WWW::App::Easy::Model::DB {
      has $!rowclass = My::Models::Example::User;
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

## Author

Timothy Totten. Catch me on #perl6 as 'supernovus'.

## License

Artistic License 2.0

