Ripple.client.
  search('zombies', 'text:run*')['response']['docs'].
  map{|d|Zombie.find d['id']}