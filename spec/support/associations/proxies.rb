

class FakeNilProxy < Ripple::Associations::Proxy
  def find_target; nil end
end

class FakeBlankProxy < Ripple::Associations::Proxy
  def find_target; '' end
end

class FakeNumberProxy < Ripple::Associations::Proxy
  def find_target; 17 end
end

class FakeProxy < Ripple::Associations::Proxy
  def find_target; [1, 2] end
end
