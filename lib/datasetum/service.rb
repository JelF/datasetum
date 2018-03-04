# frozen_string_literal: true

require 'datasetum/errors'
require 'datasetum/query'
require 'ice_nine'

module Datasetum
  # @api private
  class Service < Struct.new(:base)
    attr_accessor :primary_column

    def all
      defined?(@all) ? @all : reset_cache!
    end

    def reset_cache!
      @all = IceNine.deep_freeze(@data_source.call)
    end

    def query(request)
      joined_query = join_queries_for normalize_request(request)
      all.select { |record| joined_query.filter(record) }
    end

    def [](request)
      query(request).tap { |result| single_result_guard(request, result) }[0]
    end

    def fetch(request)
      # TODO[ruby > 2.4] replace tap with yield_self
      query(request).tap do |result|
        single_result_guard(request, result)
        break result[0] unless result.empty?

        QueringError.raise!(
          request,
          result,
          "#{base_name}.query(#{request.inspect}) returned nothing",
          caller
        )
      end
    end

    def data_source(&block)
      block ? @data_source = block : @data_source
    end

    def queries(name, options = {}, &block)
      query_builders[name] = Query::Builder.new(name, options, &block)
    end

    def join_queries_for(request)
      request.reduce(Query::TRUE) do |acc, (key, expression)|
        query = query_builders.fetch(key) do
          QueringError.raise!(request, nil, <<~TXT.strip.tr("\n", ' '), caller)
            #{base_name} do not queries #{key.inspect}.
            Available queries keys are #{query_builders.keys.inspect}
          TXT
        end

        acc & query.build(expression)
      end
    end

    private

    def normalize_request(request)
      case request
      when Hash
        request
      when Array
        join_array_request(request)
      else
        use_primary_column(request)
      end
    end

    def join_array_request(request)
      request.reduce({}) do |acc, req|
        acc.merge(normalize_request(req)) do |_key, left, right|
          [left, right].flatten
        end
      end
    end

    def use_primary_column(request)
      return { primary_column => request } if primary_column

      QueringError.raise!(request, nil, <<~TXT.strip.tr("\n", ' '), caller)
        primary column not defined for #{base_name},
        #{request} should be either hash or array of hashes
      TXT
    end

    def query_builders
      @query_builders ||= {}
    end

    def base_name
      base.name || base.inspect
    end

    def single_result_guard(request, result)
      return if result.length <= 1

      QueringError.raise!(request, result, <<~TXT.strip, caller)
        #{base_name}.query(#{request.inspect}) returned more then one record
      TXT
    end
  end
end
