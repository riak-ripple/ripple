source :rubygems

gemspec
gem 'bundler'

unless ENV['TRAVIS']
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'growl'
end
  
platforms :mri do
  gem 'yajl-ruby'
end

platforms :jruby do
  gem 'jruby-openssl'
end

group :integration do
  if ENV['RAILS31']
    gem 'activesupport', '~> 3.1.0'
  else
    gem 'activesupport', '~> 3.0.10'
  end
end

# platforms :mri_18, :jruby do
#   gem 'ruby-debug'
# end

# platforms :mri_19 do
#   gem 'ruby-debug19'
# end
