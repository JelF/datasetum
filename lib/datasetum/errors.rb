# frozen_string_literal: true

module Datasetum
  # Generalized error raised by Datum::Dataset#query, Datum::Dataset#[]
  # or Datum::Dataset#fetch
  class QueringError < StandardError
    # @return [Hash] failed request
    attr_reader :request

    # @return [nil, [Object]] response of failed request
    attr_reader :result

    # @api private
    # @param [Hash] request
    # @param [nil, [Object]] result
    # @param [String] message
    # @param [[String]] backtrace (use `#caller`)
    def self.raise!(request, result, message, backtrace)
      raise new(request, result), message, backtrace
    end

    # @api private
    # @param [Hash] request
    # @param [nil, [Object]] result
    def initialize(request, result)
      @request = request
      @result = result
      super()
    end
  end
end
