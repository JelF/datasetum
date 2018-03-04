# frozen_string_literal: true

module Datasetum
  class QueringError < StandardError
    attr_reader :request, :result

    def self.raise!(request, result, message, backtrace)
      raise new(request, result), message, backtrace
    end

    def initialize(request, result)
      @request = request
      @result = result
      super()
    end
  end
end
