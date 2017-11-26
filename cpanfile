# You can install this project with
# curl -L http://cpanmin.us | perl - https://github.com/hrards/ssh-publickey/archive/master.tar.gz
requires "perl" => "5.10.0";
requires "Applify" => "0.14";
requires "Mojolicious" => "7.55";

test_requires "Test::More" => "0.88";
test_requires "Test::Applify" => "0.05";

on develop => sub {
   requires 'https://github.com/kiwiroy/fatpack-maint-builder/releases/download/v1.1/FatPack-Maint-Build-1.1.tar.gz'
};
