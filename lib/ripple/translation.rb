require 'ripple/i18n'
require 'riak/util/translation'

module Ripple
  # Adds i18n translation/string-lookup capabilities.
  module Translation
    include Riak::Util::Translation

    # The scope of i18n keys to search (:ripple).
    def i18n_scope
      :ripple
    end
  end

  # A dummy object so translations can be accessed without module
  # inclusion.
  Translator = Object.new.tap {|o| o.extend Translation }
end
