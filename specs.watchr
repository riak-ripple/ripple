def growl(title, msg, img)
  %x{growlnotify -m #{ msg.inspect} -t #{title.inspect} --image ~/.watchr/#{img}.png}
end

def form_growl_message(str)
  results = str.split("\n").last.gsub(/\e\[\d+m/, '')
  if results =~ /[1-9]\s(pending)/
    growl "Test Results", "#{results}", "pending"
  elsif results =~ /[1-9]\s(failure|error)s?/
    growl "Test Results", "#{results}", "failed"
  elsif results != ""
    growl "Test Results", "#{results}", "passed"
  end
end

def run(cmd)
  puts(cmd)
  output = ''
  ENV['RSPEC_COLOR'] = 'true'
  IO.popen(cmd) do |com|
    com.each_char do |c|
      print c
      output << c
      $stdout.flush
    end
  end
  form_growl_message output
end

def run_test_file(file)
  run %Q(ruby -I"lib:spec" -rubygems #{file})
end

def run_all_tests
  run "rake"
end

def related_test_files(path)
  Dir['spec/**/*_spec.rb'].select { |file| file =~ /#{File.basename(path).sub('.rb', '_spec.rb')}/ }
end

watch('spec/spec_helper\.rb') { system('clear'); run_all_tests }
watch('spec/.*/.*_spec\.rb') { |m| system('clear'); run_test_file(m[0]) }
watch('lib/.*') { |m| related_test_files(m[0]).each { |file| run_test_file(file) } }

# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }

run_all_tests
