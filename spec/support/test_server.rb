require 'riak/test_server'

module TestServerSupport
  def test_server
    unless $test_server
      begin
        require 'yaml'
        config = YAML.load_file(File.expand_path("../test_server.yml", __FILE__))
        server = Riak::TestServer.create(:root => config['root'],
                                         :source => config['source'],
                                         :min_port => config['min_port'] || 15000)
        $test_server = server
      rescue => e
        pending("Can't run ripple integration specs without the test server. Specify the location of your Riak installation in spec/support/test_server.yml\n#{e.inspect}")
      end
    end
    $test_server
  end
end

RSpec.configure do |config|
  config.include TestServerSupport, :integration => true

  config.before(:each, :integration => true) do
    Ripple.config = {
      :http_port => test_server.http_port,
      :pb_port => test_server.pb_port
    }
    test_server.start
  end

  config.after(:each, :integration => true) do
    test_server.drop
  end

  config.after(:suite) do
    $test_server.stop if $test_server
  end
end
