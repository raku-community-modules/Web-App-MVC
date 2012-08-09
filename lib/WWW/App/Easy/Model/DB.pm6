use v6;

## This is not meant to be used on its own. It is a base class for your own database
## driven models. Your Model class must define a $.rowclass attribute, which must be
## either the class name or a type object representing a DB::Row sub-class.

class WWW::App::Easy::Model::DB {

  use DBIish;

  has $.rowclass;                 ## Our row class. Must be overridden.
  has $.app;                      ## The WWW::App::Easy reference.
  has $.database;                 ## Our database configuration.
  has $.table;                    ## Our database table.
  has $!dbh handles <prepare do>; ## Our database handler. Initialized on first request.

  method dbh {
    if ! $!dbh.defined {
      my $dbconfs = $.app.get-config('db');
      my $dbconf  = $dbconfs{$.database} // die 'No such database';
      my $driver  = $dbconf<driver>;
      my $opts    = $dbconf<opts>;
      $!dbh = DBIish.connect($driver, |$opts);
    }
    return $!dbh;
  }

  ## A sub-class representing a simple SQL SELECT statement.
  ## This has VERY basic commands. If you need more control, use the prepare() and
  ## execute() methods of the Model directly instead of using get().
  class SelectStatement {
    has $.model;         ## Our parent model.
    has $.sql is rw;     ## The SQL text.
    has @.bind is rw;    ## The binding values.

    submethod BUILD (:$model, :$fields='*') {
      $!model = $model;
      $!sql = "SELECT $fields FROM {$model.table}";
    }

    method !is-where {
      if $!sql !~~ /WHERE/ {
        $!sql ~= ' WHERE';
      }
    }

    method !simple-where ($op, $or, %opts) {
      my $join = $or ?? 'OR' !! 'AND';
      self!is-where;
      $!sql ~= ' (';
      my @queries;
      for %opts.kv -> $key, $val {
        @queries.push: " $key $op ?";
        @!bind.push: $val;
      }
      $!sql ~= @queries.join(" $join");
      $!sql ~= ' )';
      return self;
    }

    method with (Bool :$or?, *%opts) {
      self!simple-where('=', $or, %opts);
    }

    method not (Bool :$or?, *%opts) {
      self!simple-where('!=', $or, %opts);
    }

    method gt (Bool :$or?, *%opts) {
      self!simple-where('>', $or, %opts);
    }

    method lt (Bool :$or?, *%opts) {
      self!simple-where('<', $or, %opts);
    }

    method gte (Bool :$or?, *%opts) {
      self!simple-where('>=', $or, %opts);
    }

    method lte (Bool :$or?, *%opts) {
      self!simple-where('<=', $or, %opts);
    }

    method and {
      $!sql ~= ' AND';
      return self;
    }

    method or {
      $!sql ~= ' OR';
      return self;
    }

    ## Return a single row.
    method row {
      $!sql ~= ' LIMIT 1';
      my $stmt = $.model.prepare-select($!sql);
      my $results = $stmt.execute(|@!bind);
      if $results.elems > 0 {
        return $results[0];
      }
      return Nil;
    }

    ## Return all matching rows.
    method rows {
      my $stmt = $.model.prepare-select($!sql);
      return $stmt.execute(|@!bind);
    }
  } ## End of class SelectStatement.

  method row-class {
    if ($!rowclass ~~ Str) {
      require $!rowclass;
      $!rowclass = ::($!rowclass);
    }
    return $!rowclass;
  }

  ## Represents a prepared SELECT statement. Returns an array of result objects.
  ## NOTE: Do not use this class with anything but SELECT statements.
  class PreparedSelectStatement {
    has $.model;
    has $.sth;

    method execute (*@bind) {
      my @results;
      $.sth.execute(|@bind);
      my $class = $.model.row-class;
      while $.sth.fetchrow-hash -> %hash {
        my $row = $class.new(:model(self), :data(%hash));
        @results.push: $row;
      }
      $.sth.finish;
      return @results;
    }
  }

  ## Return a SelectStatement object.
  method get ($fields='*') {
    SelectStatement.new(:model(self), :$fields);
  }

  ## Prepare a SELECT statement.
  method prepare-select ($statement) {
    my $sth = self.prepare($statement);
    PreparedSelectStatement.new(:model(self), :$sth);
  }

  ## Create a new row.
  method newrow (*%data) {
    my $class = self.row-class;
    return $class.new(:model(self), :%data, :new-item);
  }

} ## end class WWW::App::Easy::Model::DB

## An abstract class foundation to use with your row classes.
## You MUST define a @.fields member, which maps database columns, to object attributes.

class WWW::App::Easy::Model::DB::Row {
  
  has $.model;                 ## The parent DB model object.
  has $.primary-key = 'id';    ## The default if not otherwise specified.
  has $.new-item    = False;   ## Is this a new item?

  method !get-attrs {
    my %attrs;
    for self.^attributes -> $attr {
      my $name = $attr.name.subst(/^['$'|'@'|'%']'!'/, '');
      %attrs{$name} = $attr;
    }
    return %attrs;
  }

  ## Construct a Row
  method init (:$model!, :%data!, :$new-item?) {
    my %attrs = self.get-attrs;
    if ! %attrs.exists('fields') { die "no @.fields defined in Row class."; }
    $!model = $model;
    $!new-item = $new-item;
    for @.fields -> $field {
      my $attr_name;
      my $data_name;
      if $field ~~ Pair {
        $attr_name = $field.key;
        my $fieldopts = $field.value;
        if $fieldopts ~~ Str {
          $data_name = $fieldopts;
        }
        elsif $fieldopts ~~ Hash && $fieldopts.exists('column') {
          $data_name = $fieldopts<column>;
        }
        else {
          $data_name = $attr_name;
        }

        if $fieldopts ~~ Hash && $fieldopts.exists('primary') {
          $!primary-key = $data_name;
        }
      }
      elsif $field ~~ Str {
        $attr_name = $field;
        $data_name = $field;
      }
      else {
        die "unknown field type: {$field.WHAT}";
      }

      ## We only set the field if it exists as a column and an attribute.
      if %attrs.exists($attr_name) && %data.exists($data_name) {
        my $value = %data{$data_name};
        my $load = "on-load-$attr_name";
        if self.can($load) {
          $value = self."$load"($value);
        }
        %attrs{$attr_name}.set_value(self, $value);
      }
    }
  }

  ## Pass the build procedure off to the init() method.
  submethod BUILD (:$model!, :%data!, :$new-item?) {
    self.init(:$model, :%data, :$new-item);
  }

  ## Save the row to the database.
  ## This needs some extra work to allow it to create new records with
  ## manually specified primary keys rather than assuming the use of auto-increment.
  method save {
    my @fields; ## A list of fields to set.
    my @values; ## A list of values to set.
    my $insert = $.new-item;
    my $primary-value;
    my %attrs = self.get-attrs;
    for @.fields -> $field {
      my $attr_name;
      my $data_name;
      my $fieldopts;
      if $field ~~ Pair {
        $attr_name = $field.key;
        $fieldopts = $field.value;
        if $fieldopts ~~ Str {
          $data_name = $fieldopts;
        }
        elsif $fieldopts ~~ Hash && $fieldopts.exists('column') {
          $data_name = $fieldopts<column>;
        }
        else {
          $data_name = $attr_name;
        }
      }
      elsif $field ~~ Str {
        $attr_name = $field;
        $data_name = $field;
      }
      else {
        die "unknown field type: {$field.WHAT}";
      }

      if %attrs.exists($attr_name) {
        my $value = %attrs{$attr_name}.get_value(self);
        my $save = "on-save-$attr_name";
        if self.can($save) {
          $value = self."$save"($value);
        }
        if $data_name eq $!primary-key {
          if $value.defined {
            $primary-value = $value;
            if ! $insert {
              next;
            }
          }
          else {
            if $fieldopts ~~ Hash && $fieldopts<auto> {
              $insert = True;
              next;
            }
            else {
              die "No primary key defined.";
            }
          }
        }
        if $value.defined {
          @fields.push: $data_name;
          @values.push: $value;
        }
        elsif $fieldopts ~~ Hash && $fieldopts<required> {
          die "Required field $attr_name not defined.";
        }
      }
    }
    my $fc = @fields.elems;
    my $vc = @values.elems;
    if ($fc == 0 || $vc == 0 || $fc != $vc) {
      die "Invalid data when attempting to save a DB Row.";
    }
    my $sql;
    if $insert {
      my $fc = @values.elems;
      my @q  = '?' xx $fc;
      my $fields = @fields.join(', ');
      my $values = @q.join(', ');
      $sql = "INSERT INTO {$.model.table} ($fields) VALUES ($values);";
    }
    else {
      $sql = "UPDATE {$.model.table} SET";
      my @set;
      for @fields -> $field {
        @set.push: " $field=?";
      }
      $sql ~= @set.join(',');
      $sql ~= " WHERE {$!primary-key} = $primary-value";
    }
  } ## end method save()

} ## end class WWW::App::Easy::Model::DB::Row
