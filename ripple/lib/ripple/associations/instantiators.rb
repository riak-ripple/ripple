require 'ripple/associations'

module Ripple
  module Associations
    module Instantiators

      def build(attrs={})
        instantiate_target(:new, attrs)
      end

      def create(attrs={})
        instantiate_target(:create, attrs)
      end

      def create!(attrs={})
        instantiate_target(:create!, attrs)
      end

      protected
      def instantiate_target
        raise NotImplementedError
      end

    end
  end
end
