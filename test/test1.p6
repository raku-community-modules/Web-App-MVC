use v6;

BEGIN { @*INC.push: './lib', './test'; }

use Web::App::MVC;
use Test1::Controllers::Default;
use Test1::Controllers::Dispatch;

my $app = Web::App::MVC.new(:config<./test/Test1/conf/app.json>);

$app.add(:handler(Test1::Controllers::Default), :default);
$app.add(:handler(Test1::Controllers::Dispatch));

$app.run;

