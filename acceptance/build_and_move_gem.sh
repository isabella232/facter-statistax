pwd
cd ../../facter-ng
gem build facter-ng.gemspec
cd ../facter-statistax/acceptance
mv ../../facter-ng/facter-ng-0.0.10.gem .
