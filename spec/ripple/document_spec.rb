# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Ripple::Document do
  before :all do
    Object.module_eval { class Page; include Ripple::Document; end }
  end

  it "should add bucket access methods to classes when included" do
    Page.metaclass.included_modules.should include(Ripple::Document::BucketAccess)
    Page.should respond_to(:bucket_name)
    Page.should respond_to(:bucket)
    Page.should respond_to(:bucket_name=)
  end

  it "should not be embeddable" do
    Page.should_not be_embeddable
  end

  after :all do
    Object.module_eval { remove_const(:Page) }
  end
end
