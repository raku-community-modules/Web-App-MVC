use v6;

BEGIN { @*INC.push: './lib', './test'; }

use WWW::App::Easy;
use Test1::Controller;

my $app = WWW::App::Easy.new(:config<./test/Test1/app.json>);

$app.add(:handler(Test1::Controller));

$app.run;
