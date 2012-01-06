require 'spec_helper'

describe Riak::Serializers do
  shared_examples_for "a serializer" do |type, deserialized, serialized|
    context "for #{type}" do
      it "serializes #{deserialized} to #{serialized}" do
        described_class.serialize(type, deserialized).should == serialized
      end

      it "deserializes #{serialized} to #{deserialized}" do
        described_class.deserialize(type, serialized).should == deserialized
      end

      it "round trips properly" do
        str = described_class.serialize(type, deserialized)
        described_class.deserialize(type, str).should == deserialized
      end
    end
  end

  it_behaves_like "a serializer", "text/plain", "a string", "a string"
  it_behaves_like "a serializer", "application/json", { "a" => 7 }, %q|{"a":7}|
  it_behaves_like "a serializer", "application/x-ruby-marshal", { :a => 3 }, Marshal.dump({ :a => 3 })

  described_class::YAML_MIME_TYPES.each do |mime_type|
    it_behaves_like "a serializer", mime_type, { "a" => 7 }, YAML.dump({ "a" => 7 })
  end

  %w[ serialize deserialize ].each do |meth|
    describe ".#{meth}" do
      it 'raises a NotImplementedError when given an unrecognized content type' do
        expect {
          described_class.send(meth, "application/unrecognized", "string")
        }.to raise_error(NotImplementedError)
      end
    end
  end

  describe "plain text serializer" do
    it 'calls #to_s to convert the object to a string' do
      described_class.serialize("text/plain", :a_string).should == "a_string"
    end
  end

  describe "JSON serializer" do
    it "respects the max nesting option" do
      # Sadly, this spec will not fail for me when using yajl-ruby
      # on Ruby 1.9, even when passing the options to #to_json is
      # not implemented.
      Riak.json_options = {:max_nesting => 51}
      h = {}
      p = h
      (1..50).each do |i|
        p['a'] = {}
        p = p['a']
      end
      s = h.to_json(Riak.json_options)
      expect {
        described_class.serialize('application/json', h)
      }.should_not raise_error

      expect {
        described_class.deserialize('application/json', s)
      }.should_not raise_error
    end
  end

  describe "a custom serializer" do
    let(:custom_serializer) do
      Object.new.tap do |o|
        def o.dump(string)
          "The string is: #{string}"
        end

        def o.load(string)
          string.sub!(/^The string is: /, '')
        end
      end
    end

    it 'can be registered' do
      described_class['application/custom-type-1'] = custom_serializer
      described_class['application/custom-type-1'].should be(custom_serializer)
    end

    it_behaves_like "a serializer", "application/custom-type-a", "foo", "The string is: foo" do
      before(:each) do
        described_class['application/custom-type-a'] = custom_serializer
      end
    end
  end

  it_behaves_like "a serializer", "application/json; charset=UTF-8", { "a" => 7 }, %q|{"a":7}|
  it_behaves_like "a serializer", "application/json ;charset=UTF-8", { "a" => 7 }, %q|{"a":7}|
end

