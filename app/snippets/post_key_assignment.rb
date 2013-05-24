p = Post.new key: 'first-post', name: 'first post', body: 'rad post 1000'
p.save

p.key #=> "first-post"
