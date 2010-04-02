
def switch_to_test_node
  Ripple.load_config SPEC_PATH.join('integration', 'config.yml')
end