
def mock_response(overrides={})
  {:headers => {"content-type" => ["application/json"]}, :body => '{}'}.merge(overrides)
end
