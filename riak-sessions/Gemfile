source :rubygems

gem 'bundler'
gem 'riak-client', :path => '../riak-client'
gemspec

platforms :mri do
  gem 'yajl-ruby'
end

platforms :jruby do
  gem 'json'
  gem 'jruby-openssl'
end
