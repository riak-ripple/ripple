require 'spec_helper'

module Ripple
  module Conflict
    describe Resolver do
      it 'is registered as an on conflict hook with Riak::RObject' do
        Riak::RObject.on_conflict_hooks.should include(described_class.to_proc)
      end

      describe 'calling the lambda returned by .to_proc' do
        let(:sibling_1) { stub(:data => { '_type' => 'User' } ) }
        let(:sibling_2) { stub(:data => { '_type' => 'User' } ) }
        let(:user_siblings) { [sibling_1, sibling_2] }
        let(:wheel_sibling) { stub(:data => { '_type' => 'Wheel' } ) }
        let(:robject) { stub(:siblings => user_siblings) }
        let(:resolved_robject) { stub("Resolved RObject") }
        let(:resolved_document) { stub(:robject => resolved_robject) }

        let!(:resolver) { described_class.new(robject, User) }

        it 'creates a resolver for the appropriate model class, resolves the robject, and returns the resolved robject' do
          described_class.
            should_receive(:new).
            with(robject, User).
            and_return(resolver)

          resolver.should_receive(:resolve)
          resolver.stub(:document => resolved_document)

          described_class.to_proc.call(robject).should be(resolved_robject)
        end

        it 'returns nil and does not attempt resolution when given an robject with siblings of different types' do
          user_siblings << wheel_sibling
          described_class.should_not_receive(:new)
          described_class.to_proc.call(robject).should be_nil
        end
      end
    end
  end
end

