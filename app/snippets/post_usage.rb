p = Post.new
p.name = "first post"
p.body = "this post is rad!!!\n" * 10

p.save

p.key #=> "37458abc752f8413e"

p2 = Post.find "37458abc752f8413e"

p.name #=> "first post"
