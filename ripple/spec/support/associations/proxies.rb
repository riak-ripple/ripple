# yet another filch from mongo mapper
class FakeNilProxy < Ripple::Document::Associations::Proxy
  def find_target; nil end
end

class FakeBlankProxy < Ripple::Document::Associations::Proxy
  def find_target; '' end
end

class FakeNumberProxy < Ripple::Document::Associations::Proxy
  def find_target; 17 end
end

class FakeProxy < Ripple::Document::Associations::Proxy
  def find_target; [1, 2] end
end
