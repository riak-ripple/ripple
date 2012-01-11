class Post
  include Ripple::Document
  one :user, :using => :stored_key
  many :comments, :using => :stored_key
  property :comment_keys, Array
  property :user_key, String
  property :title, String
end

class Comment
  include Ripple::Document
end
