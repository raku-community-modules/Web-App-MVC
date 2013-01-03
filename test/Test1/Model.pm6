use v6;
use WWW::App::MVC::Model::DB;

class Test1::Model::Row is WWW::App::MVC::Model::DB::Row {
  has $.id;
  has $.name is rw;
  has $.age  is rw;
  has $.job  is rw;

  has @.fields = 'id' => {:primary, :auto}, 'name', 'age', 'job';

  method birthyear {
    my $this-year = Date.today.year;
    return $this-year - $.age;
  }
}

class Test1::Model is WWW::App::MVC::Model::DB {
  has $.rowclass = Test1::Model::Row;
}

