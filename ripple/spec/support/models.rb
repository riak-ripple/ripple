Dir[File.expand_path("../models/*.rb", __FILE__)].each do |file|
  require file
end
