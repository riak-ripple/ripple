require 'spec_helper'

describe Riak::Client::HTTPBackend::Configuration do
  let(:client){ Riak::Client.new }
  let(:node){ client.node }
  subject { Riak::Client::HTTPBackend.new(client, node) }
  let(:uri){ URI.parse("http://127.0.0.1:8098/") }

  context "generating resource URIs" do
    context "when using the old scheme" do
      before { subject.should_receive(:get).with(200, uri).and_return(:headers => {'link' => ['</riak>; rel="riak_kv_wm_raw", </ping>; rel="riak_kv_wm_ping", </stats>; rel="riak_kv_wm_stats", </mapred>; rel="riak_kv_wm_mapred"']}) }

      it "should generate a ping path" do
        url = subject.ping_path
        url.should be_kind_of(URI)
        url.path.should == '/ping'
      end

      it "should generate a stats path" do
        url = subject.stats_path
        url.should be_kind_of(URI)
        url.path.should == '/stats'
      end

      it "should generate a mapred path" do
        url = subject.mapred_path :chunked => true
        url.should be_kind_of(URI)
        url.path.should == '/mapred'
        url.query.should == "chunked=true"
      end

      it "should generate a bucket list path" do
        url = subject.bucket_list_path
        url.should be_kind_of(URI)
        url.path.should == '/riak'
        url.query.should == 'buckets=true'
      end

      it "should generate a bucket properties path" do
        url = subject.bucket_properties_path('test ')
        url.should be_kind_of(URI)
        url.path.should == '/riak/test%20'
        url.query.should == "keys=false&props=true"
      end

      it "should generate a key list path" do
        url = subject.key_list_path('test ')
        url.should be_kind_of(URI)
        url.path.should == '/riak/test%20'
        url.query.should == 'keys=true&props=false'
        url = subject.key_list_path('test ', :keys => :stream)
        url.path.should == '/riak/test%20'
        url.query.should == 'keys=stream&props=false'
      end

      it "should generate an object path" do
        url = subject.object_path('test ', 'object/', :r => 3)
        url.should be_kind_of(URI)
        url.path.should == '/riak/test%20/object%2F'
        url.query.should == 'r=3'
      end

      it "should generate a link-walking path" do
        url = subject.link_walk_path('test ', 'object/', [Riak::WalkSpec.new(:bucket => 'foo')])
        url.should be_kind_of(URI)
        url.path.should == '/riak/test%20/object%2F/foo,_,_'
      end

      it "should raise an error when generating an index range path" do
        expect { subject.index_range_path('test', 'index_bin', 'a', 'b') }.to raise_error
      end

      it "should raise an error when generating an index equal path" do
        expect { subject.index_eq_path('test', 'index_bin', 'a') }.to raise_error
      end
    end

    context "when using the new scheme" do
      before { subject.should_receive(:get).with(200, uri).and_return(:headers => {'link' => ['</buckets>; rel="riak_kv_wm_buckets", </ping>; rel="riak_kv_wm_ping", </stats>; rel="riak_kv_wm_stats", </mapred>; rel="riak_kv_wm_mapred"']}) }

      it "should generate a ping path" do
        url = subject.ping_path
        url.should be_kind_of(URI)
        url.path.should == '/ping'
      end

      it "should generate a stats path" do
        url = subject.stats_path
        url.should be_kind_of(URI)
        url.path.should == '/stats'
      end

      it "should generate a mapred path" do
        url = subject.mapred_path :chunked => true
        url.should be_kind_of(URI)
        url.path.should == '/mapred'
        url.query.should == "chunked=true"
      end

      it "should generate a bucket list path" do
        url = subject.bucket_list_path
        url.should be_kind_of(URI)
        url.path.should == '/buckets'
        url.query.should == 'buckets=true'
      end

      it "should generate a bucket properties path" do
        url = subject.bucket_properties_path('test ')
        url.should be_kind_of(URI)
        url.path.should == '/buckets/test%20/props'
        url.query.should be_nil
      end

      it "should generate a key list path" do
        url = subject.key_list_path('test ')
        url.should be_kind_of(URI)
        url.path.should == '/buckets/test%20/keys'
        url.query.should == 'keys=true'
        url = subject.key_list_path('test ', :keys => :stream)
        url.path.should == '/buckets/test%20/keys'
        url.query.should == 'keys=stream'
      end

      it "should generate an object path" do
        url = subject.object_path('test ', 'object/', :r => 3)
        url.should be_kind_of(URI)
        url.path.should == '/buckets/test%20/keys/object%2F'
        url.query.should == 'r=3'
      end

      it "should generate a link-walking path" do
        url = subject.link_walk_path('test ', 'object/', [Riak::WalkSpec.new(:bucket => 'foo')])
        url.should be_kind_of(URI)
        url.path.should == '/buckets/test%20/keys/object%2F/foo,_,_'
      end

      it "should generate an index range path" do
        url = subject.index_range_path('test ', 'test_bin', 'a', 'b')
        url.should be_kind_of(URI)
        url.path.should == '/buckets/test%20/index/test_bin/a/b'
      end

      it "should generate an index equal path" do
        url = subject.index_eq_path('test ', 'test_bin', 'a')
        url.should be_kind_of(URI)
        url.path.should == '/buckets/test%20/index/test_bin/a'
      end
    end
  end

  it "should memoize the server config" do
    subject.should_receive(:get).with(200, uri).once.and_return(:headers => {'link' => ['</riak>; rel="riak_kv_wm_link_walker",</mapred>; rel="riak_kv_wm_mapred",</ping>; rel="riak_kv_wm_ping",</riak>; rel="riak_kv_wm_raw",</stats>; rel="riak_kv_wm_stats"']})
    subject.send(:riak_kv_wm_link_walker).should == "/riak"
    subject.send(:riak_kv_wm_raw).should == "/riak"
  end

  context "generating Solr paths" do
    context "when Riak Search is disabled" do
      before {
        subject.should_receive(:get).with(200, uri).once.and_return(:headers => {'link' => ['</riak>; rel="riak_kv_wm_link_walker",</mapred>; rel="riak_kv_wm_mapred",</ping>; rel="riak_kv_wm_ping",</riak>; rel="riak_kv_wm_raw",</stats>; rel="riak_kv_wm_stats"']})
      }

      it "should raise an error" do
        expect { subject.solr_select_path('foo', 'a:b') }.to raise_error
        expect { subject.solr_update_path('foo') }.to raise_error
      end
    end

    context "when Riak Search is enabled" do
      before {
        subject.should_receive(:get).with(200, uri).once.and_return(:headers => {'link' => ['</riak>; rel="riak_kv_wm_link_walker",</mapred>; rel="riak_kv_wm_mapred",</ping>; rel="riak_kv_wm_ping",</riak>; rel="riak_kv_wm_raw",</stats>; rel="riak_kv_wm_stats", </solr>; rel="riak_solr_indexer_wm", </solr>; rel="riak_solr_searcher_wm"']})
      }

      it "should generate a search path for the default index" do
        url = subject.solr_select_path(nil, 'a:b')
        url.should be_kind_of(URI)
        url.path.should == '/solr/select'
        url.query.should include("q=a%3Ab")
        url.query.should include('wt=json')
      end

      it "should generate a search path for a specified index" do
        url = subject.solr_select_path('foo', 'a:b', 'wt' => 'xml')
        url.should be_kind_of(URI)
        url.path.should == '/solr/foo/select'
        url.query.should include("q=a%3Ab")
        url.query.should include('wt=xml')
      end

      it "should generate an indexing path for the default index" do
        url = subject.solr_update_path(nil)
        url.should be_kind_of(URI)
        url.path.should == '/solr/update'
      end

      it "should generate an indexing path for a specified index" do
        url = subject.solr_update_path('foo')
        url.should be_kind_of(URI)
        url.path.should == '/solr/foo/update'
      end
    end
  end

  {
    :riak_kv_wm_raw => :prefix,
    :riak_kv_wm_link_walker => :prefix,
    :riak_kv_wm_mapred => :mapred
  }.each do |resource, alternate|
    it "should detect the #{resource} resource from the configuration URL" do
      subject.should_receive(:get).with(200, uri).and_return(:headers => {'link' => [%Q{</path>; rel="#{resource}"}]})
      subject.send(resource).should == "/path"
    end

    it "should fallback to node.http_paths[:#{alternate}] if the #{resource} resource is not found" do
      subject.should_receive(:get).with(200, uri).and_return(:headers => {'link' => ['</>; rel="top"']})
      subject.send(resource).should == node.http_paths[alternate]
    end

    it "should fallback to node.http_paths[:#{alternate}] if request fails" do
      subject.should_receive(:get).with(200, uri).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, ""))
      subject.send(resource).should == node.http_paths[alternate]
    end
  end

  {
    :riak_kv_wm_ping => "/ping",
    :riak_kv_wm_stats => "/stats"
  }.each do |resource, default|
    it "should detect the #{resource} resource from the configuration URL" do
      subject.should_receive(:get).with(200, uri).and_return(:headers => {'link' => [%Q{</path>; rel="#{resource}"}]})
      subject.send(resource).should == "/path"
    end
    it "should fallback to #{default.inspect} if the #{resource} resource is not found" do
      subject.should_receive(:get).with(200, uri).and_return(:headers => {'link' => ['</>; rel="top"']})
      subject.send(resource).should == default
    end
    it "should fallback to #{default.inspect} if request fails" do
      subject.should_receive(:get).with(200, uri).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, ""))
      subject.send(resource).should == default
    end
  end
end
