
# Load JSON
unless defined? JSON
  begin
    require 'yajl/json_gem'
  rescue LoadError
    require 'json'
  end
end
