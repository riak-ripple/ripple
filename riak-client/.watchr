watch("spec/(.*)_spec.rb") {|md| system %Q[echo "-----------------------------------------"; rvm --with-rubies jruby,1.8.7,1.9.2 exec "rvm tools identifier; echo; rspec #{md[0]}"] }
trap("INT") { exit }
