# frozen_string_literal: true

require 'datasetum/errors'
require 'datasetum/query'
require 'ice_nine'

module Datasetum
  # Datasetum::Dataset delegates to instance of this class to provide better
  # incapsulation (no private api methods in main module)
  # @api private
  class Service < Struct.new(:base)
    # @!attribute base
    #   @return [Class] class where Datasetum::Dataset extended

    # @return [nil, Symbol]
    #   "default" column which used when column not specified
    # @example
    #   Dataset[name: "Eld"] # => <Rune name="Eld">
    #   Dataset["Eld"] # => Error
    #   Dataset.send(:primary_column=, :name)
    #   Dataset["Eld"] # => <Rune name="Eld">
    attr_accessor :primary_column

    # @return [proc { [Object] }] proc which returns all records
    # @example
    #   class Rune
    #     extend Datasetum::Dataset
    #     SOURCE_PATH = ROOT.join('data', 'runes.yml')
    #     self.data_source = -> { YAML.load_file(SOURCE_PATH) }
    #   end
    attr_accessor :data_source

    # @return [[Object]] full dataset as it returned from data_source
    def all
      defined?(@all) ? @all : reset_cache!
    end

    # Reset cache and load new dataset from #data_source
    # @return [[Object]] full dataset as it returned from data_source
    def reset_cache!
      @all = IceNine.deep_freeze(data_source.call)
    end

    # Dsl for `all.select { ... }`
    # @see #queries queries method to get more information
    # @param [[Hash], Hash, [Object], Object] request
    # @raise [QueringError] if key not registered with #queries
    # @return [[Object]]
    # @example find by column value
    #   Dataset.query(name: 'Eld') => [<Rune name="Eld">]
    # @example find by one of column values
    #   Dataset.query(name: ['El', 'Eld'])
    #     => [<Rune name="El">, <Rune name="Eld">]
    # @example find by range of column values
    #   Dataset.query(level: 1..11)
    #     => [<Rune name="El">, <Rune name="Eld">]
    # @example find by range of column values
    #   Dataset.query(level: 1..11)
    #     => [<Rune name="El">, <Rune name="Eld">]
    # @example find by primary_column (it should be set up!)
    #   Dataset.query('El') => [<Rune name="El">]
    # @example Just in case you need it
    #   Dataset.query([{ name: 'El'}, { name: 'Eld'}])
    #     => [<Rune name="El">, <Rune name="Eld">]
    def query(request)
      joined_query = join_queries_for normalize_request(request)
      all.select { |record| joined_query.filter(record) }
    end

    # Dsl for `all.find { ... }`. Same as #query but returns one record or nil
    # @param [[Hash], Hash, [Object], Object] request
    # @raise [QueringError] if key not registered with #queries
    # @raise [QueringError] if multiple records found
    # @return [nil, Object]
    # @example
    #   Dataset[name: 'Eld'] #=> <Rune name="Eld">
    # @see #query
    def [](request)
      query(request).tap { |result| single_result_guard(request, result) }[0]
    end

    # Dsl for `all.find { ... }`. Same as #query but returns one record
    # @param [[Hash], Hash, [Object], Object] request
    # @raise [QueringError] if key not registered with #queries
    # @raise [QueringError] if multiple records found
    # @raise [QueringError] if no records found
    # @return [Object]
    # @example
    #   Dataset.fetch(name: 'Eld') #=> <Rune name="Eld">
    # @see #query
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

    # Declare a key for #query
    # @param name [Symbol] key for #query
    # @param options [Hash]
    # @param block [proc { |expression, record| Boolean }]
    #   allows to implement your own logic
    # @option options [:block, :equality] factory (`block ? :block : :equality`)
    #   Specifies factory to make a query. Right now it is useless,
    #   but i plan to add special factories which siplifies
    #   queriing array fields and maybe other stuff.
    #   Do not set it now, beacause default value always correct
    # @option options [Symbol] field (name)
    #   Specifies field to query in equality strategy. Not usefull because
    #   better strategy is to alias field in model instead of doing it here
    # @raise if factory not found
    # @see #query
    # @see Datasetum::QueryRefinements
    # @example assuming equality factory
    #   queries :name
    # @example assuming block factory
    #   using Dataset::QueryRefinements
    #   queries :name do |expression, record|
    #     expression.match_any?(record.name)
    #   end
    # @example same with instance_exec dsl (zero arity required)
    #   using Dataset::QueryRefinements
    #   queries(:name) { expression.match_any? field }
    # @example complicated usage
    #   using Dataset::QueryRefinements
    #   queries :runes do
    #     field.all? { |x| expression.match_any?(x) }
    #   end
    #   # This will match only records with all runes enumerated in query
    def queries(name, options = {}, &block)
      query_builders[name] = Query::Builder.new(name, options, &block)
    end

    private

    # @param [Hash] request
    # @return [Query::Built]
    #  joined queries for request fetched from #query_builders
    # @see #query_builders
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

    # @param [Hash, Object, [Hash], [Object]] request
    # @return [Hash] normalized request
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

    # @param [[Hash, Object]] request
    # @return [Hash] normalized request
    def join_array_request(request)
      request.reduce({}) do |acc, req|
        acc.merge(normalize_request(req)) do |_key, left, right|
          [left, right].flatten
        end
      end
    end

    # @param [Object] request
    # @return [Hash] normalized request
    def use_primary_column(request)
      return { primary_column => request } if primary_column

      QueringError.raise!(request, nil, <<~TXT.strip.tr("\n", ' '), caller)
        primary column not defined for #{base_name},
        #{request} should be either hash or array of hashes
      TXT
    end

    # @return [Symbol => Query::Builder] all registered query builders
    def query_builders
      @query_builders ||= {}
    end

    # @return [String] human-readable name of base class
    def base_name
      base.name || base.inspect
    end

    # @param [Hash] request processed request
    # @param [[Object]] result response of #query
    # @raise [QueringError] if multiple records given
    # @see #[]
    def single_result_guard(request, result)
      return if result.length <= 1

      QueringError.raise!(request, result, <<~TXT.strip, caller)
        #{base_name}.query(#{request.inspect}) returned more then one record
      TXT
    end
  end
end
