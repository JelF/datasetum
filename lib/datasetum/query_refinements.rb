# frozen_string_literal: true

module Datasetum
  module QueryRefinements
    refine Object do
      def safe_to_array
        [self]
      end

      def match_elem?(x)
        self == x
      end

      def match_any?(xs)
        xs.safe_to_array.any? { |x| match_elem?(x) }
      end

      def match_all?(xs)
        xs.safe_to_array.all? { |x| match_elem?(x) }
      end
    end

    refine Range do
      def safe_to_array
        to_a
      end

      alias_method :match_elem?, :include?
    end

    refine Array do
      def safe_to_array
        self
      end

      def match_elem?(x)
        any? { |t| t.match_elem?(x) }
      end
    end

    refine Proc do
      alias_method :match_elem?, :call
    end
  end
end
