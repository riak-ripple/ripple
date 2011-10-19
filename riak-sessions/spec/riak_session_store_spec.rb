require 'spec_helper'
require 'rack/mock'

describe Riak::SessionStore do
  before do
    Riak::SessionStore::DEFAULT_OPTIONS[:http_port] = $test_server.http_port
  end
  session_key = Riak::SessionStore::DEFAULT_OPTIONS[:key]
  session_match = /#{session_key}=([0-9a-fA-F]+);/
  incrementor = lambda do |env|
    env["rack.session"]["counter"] ||= 0
    env["rack.session"]["counter"] += 1
    Rack::Response.new(env["rack.session"].inspect).to_a
  end
  drop_session = proc do |env|
    env['rack.session.options'][:drop] = true
    incrementor.call(env)
  end
  renew_session = proc do |env|
    env['rack.session.options'][:renew] = true
    incrementor.call(env)
  end
  defer_session = proc do |env|
    env['rack.session.options'][:defer] = true
    incrementor.call(env)
  end
  reset_session = proc do |env|
    env['rack.session.options'].delete(:id)
    env['rack.session'] = {}
    incrementor.call(env)
  end

  it "creates a new cookie" do
    pool = Riak::SessionStore.new(incrementor)
    res = Rack::MockRequest.new(pool).get("/")
    res["Set-Cookie"].should include("#{session_key}=")
    res.body.should == '{"counter"=>1}'
  end

  it "determines session from a cookie" do
    pool = Riak::SessionStore.new(incrementor)
    req = Rack::MockRequest.new(pool)
    res = req.get("/")
    cookie = res["Set-Cookie"]
    req.get("/", "HTTP_COOKIE" => cookie).
      body.should == '{"counter"=>2}'
    req.get("/", "HTTP_COOKIE" => cookie).
      body.should == '{"counter"=>3}'
  end

  it "survives nonexistant cookies" do
    bad_cookie = "rack.session=#{Digest::SHA1.hexdigest(Time.now.to_s)}"
    pool = Riak::SessionStore.new(incrementor)
    res = Rack::MockRequest.new(pool).
      get("/", "HTTP_COOKIE" => bad_cookie)
    res.body.should == '{"counter"=>1}'
    cookie = res["Set-Cookie"][session_match]
    cookie.should_not match(/#{bad_cookie}/)
  end

  it "maintains freshness" do
    now = Time.now
    old_now = Time.method(:now)
    Time.stub(:now).and_return(now)
    pool = Riak::SessionStore.new(incrementor, :expire_after => 3)
    res = Rack::MockRequest.new(pool).get('/')
    res.body.should include '"counter"=>1'
    cookie = res["Set-Cookie"]
    res = Rack::MockRequest.new(pool).get('/', "HTTP_COOKIE" => cookie)
    res["Set-Cookie"].should == cookie
    res.body.should include '"counter"=>2'
    puts 'Sleeping to expire session' if $DEBUG
    sleep 4
    Time.stub(:now, &old_now)
    res = Rack::MockRequest.new(pool).get('/', "HTTP_COOKIE" => cookie)
    res["Set-Cookie"].should_not == cookie
    res.body.should include '"counter"=>1'
  end

  it "deletes cookies with :drop option" do
    pool = Riak::SessionStore.new(incrementor)
    req = Rack::MockRequest.new(pool)
    drop = Rack::Utils::Context.new(pool, drop_session)
    dreq = Rack::MockRequest.new(drop)

    res0 = req.get("/")
    session = (cookie = res0["Set-Cookie"])[session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get("/", "HTTP_COOKIE" => cookie)
    res1["Set-Cookie"][session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = dreq.get("/", "HTTP_COOKIE" => cookie)
    res2["Set-Cookie"].should == nil
    res2.body.should == '{"counter"=>3}'

    res3 = req.get("/", "HTTP_COOKIE" => cookie)
    res3["Set-Cookie"][session_match].should_not == session
    res3.body.should == '{"counter"=>1}'
  end

  it "provides new session id with :renew option" do
    pool = Riak::SessionStore.new(incrementor)
    req = Rack::MockRequest.new(pool)
    renew = Rack::Utils::Context.new(pool, renew_session)
    rreq = Rack::MockRequest.new(renew)

    res0 = req.get("/")
    session = (cookie = res0["Set-Cookie"])[session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get("/", "HTTP_COOKIE" => cookie)
    res1["Set-Cookie"][session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = rreq.get("/", "HTTP_COOKIE" => cookie)
    new_cookie = res2["Set-Cookie"]
    new_session = new_cookie[session_match]
    new_session.should_not == session
    res2.body.should == '{"counter"=>3}'

    res3 = req.get("/", "HTTP_COOKIE" => new_cookie)
    res3["Set-Cookie"][session_match].should == new_session
    res3.body.should == '{"counter"=>4}'
  end

  it "omits cookie with :defer option" do
    pool = Riak::SessionStore.new(incrementor)
    req = Rack::MockRequest.new(pool)
    defer = Rack::Utils::Context.new(pool, defer_session)
    dreq = Rack::MockRequest.new(defer)

    res0 = req.get("/")
    session = (cookie = res0["Set-Cookie"])[session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get("/", "HTTP_COOKIE" => cookie)
    res1["Set-Cookie"][session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = dreq.get("/", "HTTP_COOKIE" => cookie)
    res2["Set-Cookie"].should == nil
    res2.body.should == '{"counter"=>3}'

    res3 = req.get("/", "HTTP_COOKIE" => cookie)
    res3["Set-Cookie"][session_match].should == session
    res3.body.should == '{"counter"=>4}'
  end

  it "should store the session as marshaled Ruby" do
    client = Riak::Client.new(Riak::SessionStore::DEFAULT_OPTIONS.slice(*Riak::Client::VALID_OPTIONS))
    pool = Riak::SessionStore.new(incrementor)
    res = Rack::MockRequest.new(pool).get("/")
    session_id = res["Set-Cookie"].gsub(/rack\.session=([a-z0-9]+);.+$/, '\1')
    session = client.bucket('_sessions').get(session_id)
    session.content_type.should == "application/x-ruby-marshal"
  end

  it "should create a new session when the session is harshly reset" do
    pool = Riak::SessionStore.new(incrementor)
    req = Rack::MockRequest.new(pool)
    reset_session = Rack::Utils::Context.new(pool, reset_session)
    reset_req = Rack::MockRequest.new(reset_session)

    res0 = req.get("/")
    session = (cookie = res0["Set-Cookie"])[session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get("/", "HTTP_COOKIE" => cookie)
    res1["Set-Cookie"][session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = reset_req.get("/", "HTTP_COOKIE" => cookie)
    res2["Set-Cookie"][session_match].should_not == session
    res2.body.should == '{"counter"=>1}'
  end

  it "should delete the old session when the session is harshly reset" do
    pool = Riak::SessionStore.new(incrementor)
    req = Rack::MockRequest.new(pool)
    reset_session = Rack::Utils::Context.new(pool, reset_session)
    reset_req = Rack::MockRequest.new(reset_session)

    res0 = req.get("/")
    session = (cookie = res0["Set-Cookie"])[session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get("/", "HTTP_COOKIE" => cookie)
    res1["Set-Cookie"][session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = reset_req.get("/", "HTTP_COOKIE" => cookie)

    client = Riak::Client.new(Riak::SessionStore::DEFAULT_OPTIONS.slice(*Riak::Client::VALID_OPTIONS))
    expect {
      client.bucket('_session').get(session)
    }.to raise_error(Riak::HTTPFailedRequest)
  end

end
