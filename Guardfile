# A sample Guardfile
# More info at https://github.com/guard/guard#readme
gemset = ENV['RVM_GEMSET'] || 'ripple'
gemset = "@#{gemset}" unless gemset.to_s == ''

rvms = %w[ 1.8.7 1.9.2 1.9.3 jruby ].map do |version|
  "#{version}@#{gemset}"
end

guard 'rspec', :cli => '--profile', :rvm => rvms do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{lib/rails/generators(.*)(\w+)/\2_generator\.rb}) {|m| "spec/generators#{m[1]}#{m[2]}_generator_spec.rb" }
  watch(%r{lib/rails/generators(.*)(\w+)/templates}) {|m| "spec/generators#{m[1]}#{m[2]}_generator_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec/ripple" }
end

