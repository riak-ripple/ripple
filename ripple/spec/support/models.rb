
Dir[File.expand_path("../models/*.rb", __FILE__)].sort.each do |file|
  require "support/models/#{File.basename(file)}"
end
