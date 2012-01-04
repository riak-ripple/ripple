require 'spec_helper'
require 'rails/generators/ripple/model/model_generator'

shared_examples_for :model_generator do
  it("should create the model file"){ model_file.should exist }
  it { should contain(class_decl) }
  it("should create the attribute declarations") do
    attributes.each do |name, type|
      should contain("property :#{name}, #{type}")
    end
  end
end

shared_examples_for :subclass_model_generator do
  it_behaves_like :model_generator
  it { should_not contain("include Ripple::Document") }
  it { should_not contain("include Ripple::EmbeddedDocument") }
end

shared_examples_for :embedded_document_generator do
  it_behaves_like :model_generator
  it { should contain("include Ripple::EmbeddedDocument") }
end

shared_examples_for :document_generator do
  it_behaves_like :model_generator
  it { should contain("include Ripple::Document") }
end

describe Ripple::Generators::ModelGenerator do
  let(:cli){ %w{general_model} }
  let(:model_file){ file('app/models/general_model.rb') }
  let(:class_decl){ "class GeneralModel" }
  let(:attributes){ {} }
  subject { model_file }
  before { run_generator cli }
  
  describe "generating a bare model" do
    it_behaves_like :document_generator
  end

  describe "generating with attributes" do
    let(:cli){ %w{general_model name:string shipped:datetime size:integer} }
    let(:attributes) { {:name => String, :shipped => Time, :size => Integer } }
    it_behaves_like :document_generator
  end

  describe "generating a model with a parent class" do
    let(:cli){ %w{general_model --parent=widget} }
    let(:class_decl){ "class GeneralModel < Widget" }
    it_behaves_like :subclass_model_generator
  end

  describe "generating an embedded model" do
    let(:cli){ %w{general_model --embedded} }
    it_behaves_like :embedded_document_generator
  end

  describe "generating a model embedded in a parent document" do
    let(:cli){ %w{general_model --embedded-in=widget} }
    it_behaves_like :embedded_document_generator
    it { should contain("embedded_in :widget") }
  end
end
