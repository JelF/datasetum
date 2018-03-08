# frozen_string_literal: true

module Datasetum
  # Refinements to simplify querying
  # @example
  #   use Datasetum::QueryRefinements
  #   [1, 2, 3].match_all? 1..2 # => true
  module QueryRefinements
    # @!method safe_to_array
    #   like Array(self) but without surpries
    #   @example Object
    #     123.safe_to_array # => [123]
    #   @example Range
    #     (1..3).safe_to_array # => [1, 2, 3]
    #   @example Array
    #     [123, []].safe_to_array # => [123, []]
    #   @return [Array]

    # @!method match_elem?(elem)
    #   primary match expression. Not expect to receive arrays
    #   @param elem [Object] not array!
    #   @example Object
    #     123.match_elem? 123 # => true
    #     123.match_elem? 456 # => false
    #   @example Range
    #     (100..200).match_elem? 123 # => true
    #     (100..200).match_elem? 456 # => false
    #   @example Array
    #     [123, 312].match_elem? 123 # => true
    #     [123, 312].match_elem? 456 # => false
    #   @return [Boolean]

    # @!method match_any?(elems)
    #   match any element of array. Objects casted to array via #safe_to_array
    #   @param elems [Object]
    #   @example
    #     123.match_any? 123 # => true
    #     123.match_any? [123, 456] # => true
    #     123.match_any? [] # => false
    #     123.match_any? 100..200 # => true and really slow
    #   @return [Boolean]

    # @!method match_all?(elems)
    #   match all elements of array. Objects casted to array via #safe_to_array
    #   @param elems [Object]
    #   @example
    #     123.match_all? 123 # => true
    #     123.match_all? [123] # => true
    #     123.match_all? [123, 456] # => false
    #     [1, 2, 3].match_all? 1..2 # => true
    #   @return [Boolean]
    refine Object do
      def safe_to_array
        [self]
      end

      def match_elem?(elem)
        self == elem
      end

      def match_any?(elems)
        elems.safe_to_array.any? { |elem| match_elem?(elem) }
      end

      def match_all?(elems)
        array = elems.safe_to_array
        return false if array.empty?
        array.all? { |elem| match_elem?(elem) }
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

      def match_elem?(elem)
        any? { |t| t.match_elem?(elem) }
      end
    end

    refine Proc do
      alias_method :match_elem?, :call
    end
  end
end
