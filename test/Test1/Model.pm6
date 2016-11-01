use v6;
use DB::Model::Easy;
use DB::Model::Easy::Row;

class Test1::Model::Row is DB::Model::Easy::Row {
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

class Test1::Model is DB::Model::Easy {
  has $.rowclass = Test1::Model::Row;
}

