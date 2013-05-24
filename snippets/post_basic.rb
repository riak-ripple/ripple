class Post
  include Ripple::Document

  property :name, String, presence: true
  property :body, String, presence: true

  timestamps!
end
