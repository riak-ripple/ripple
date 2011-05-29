
describe Riak do
  require 'riak/core_ext/to_param'

  it "should do param conversion correctly" do
    { :name => 'David', :nationality => 'Danish' }.to_param.should == "name=David&nationality=Danish"
  end

  # Based on the activesupport implementation.
  # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/to_param.rb
  it "should do param conversion correctly with a namespace" do
    { :name => 'David', :nationality => 'Danish' }.to_param('user').should == "user%5Bname%5D=David&user%5Bnationality%5D=Danish"
  end

end
