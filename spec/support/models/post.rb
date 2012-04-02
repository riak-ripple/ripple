class Post
  include Ripple::Document
  property :comment_keys, Array
  property :user_key, String
  property :title, String

  one :user, :using => :stored_key
  many :comments, :using => :stored_key
end

class Comment
  include Ripple::Document
end
