require 'mkmf'
#cpp_command('g++')
have_library("stdc++")
dir_config('protobuf')
unless have_library('protobuf')
  $stderr.puts "Please install protobuf-2.3.0 for your system."
  exit 1
end
create_makefile('riakpb')
