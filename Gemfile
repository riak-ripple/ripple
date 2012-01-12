source :rubygems

gemspec

if ENV['RAILS31']
  gem 'activemodel', '~> 3.1.0'
else
  gem 'activemodel', '~> 3.0.10'
end

if ENV['TRAVIS']
  # Once the APIs are stable, this should be removed
  gem 'riak-client', :git => "git://github.com/basho/riak-ruby-client.git"
else
  # Comment this gem out if you are using a stable version of
  # riak-client in development
  gem 'riak-client', :path => "../riak-client"
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'growl'
end

platforms :jruby do
  gem 'jruby-openssl'
end
