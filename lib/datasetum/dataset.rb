# frozen_string_literal: true

require 'datasetum/service'

module Datasetum
  # Main entry point of gem wich exposes it's API
  module Dataset
    extend Forwardable

    def_delegators(
      :__datasetum_service,
      :all, :reset_cache!, :query, :[], :fetch, :queries,
      :data_source, :data_source=, :primary_column, :primary_column=
    )

    private :data_source, :queries, :primary_column, :primary_column=

    # @api private
    # @return [Datasetum::Service]
    private def __datasetum_service
      @__datasetum_service ||= Service.new(self)
    end

    # @!attribute primary_column
    #   @return [nil, Symbol]
    #     "default" column which used when column not specified
    #   @example
    #     Dataset[name: "Eld"] # => <Rune name="Eld">
    #     Dataset["Eld"] # => Error
    #     Dataset.send(:primary_column=, :name)
    #     Dataset["Eld"] # => <Rune name="Eld">

    # @!attribute data_source
    #   @return [proc { [Object] }] proc which returns all records
    #   @example
    #     class Rune
    #       extend Datasetum::Dataset
    #       SOURCE_PATH = ROOT.join('data', 'runes.yml')
    #       self.data_source = -> { YAML.load_file(SOURCE_PATH) }
    #     end

    # @!method all
    #   @return [[Object]] full dataset as it returned from data_source

    # @!method reset_cache!
    #   Reset cache and load new dataset from #data_source
    #   @return [[Object]] full dataset as it returned from data_source

    # @!method query(request)
    #   Dsl for `all.select { ... }`
    #   @see #queries queries method to get more information
    #   @param [[Hash], Hash, [Object], Object] request
    #   @raise [QueringError] if key not registered with #queries
    #   @return [[Object]]
    #   @example find by column value
    #     Dataset.query(name: 'Eld') => [<Rune name="Eld">]
    #   @example find by one of column values
    #     Dataset.query(name: ['El', 'Eld'])
    #       => [<Rune name="El">, <Rune name="Eld">]
    #   @example find by range of column values
    #     Dataset.query(level: 1..11)
    #       => [<Rune name="El">, <Rune name="Eld">]
    #   @example find by range of column values
    #     Dataset.query(level: 1..11)
    #       => [<Rune name="El">, <Rune name="Eld">]
    #   @example find by primary_column (it should be set up!)
    #     Dataset.query('El') => [<Rune name="El">]
    #   @example Just in case you need it
    #     Dataset.query([{ name: 'El'}, { name: 'Eld'}])
    #       => [<Rune name="El">, <Rune name="Eld">]

    # @!method [](request)
    #   Dsl for `all.find { ... }`. Same as #query but returns one record or nil
    #   @param [[Hash], Hash, [Object], Object] request
    #   @raise [QueringError] if key not registered with #queries
    #   @raise [QueringError] if multiple records found
    #   @return [nil, Object]
    #   @example
    #     Dataset[name: 'Eld'] #=> <Rune name="Eld">
    #   @see #query

    # @!method fetch(request)
    #   Dsl for `all.find { ... }`. Same as #query but returns one record
    #   @param [[Hash], Hash, [Object], Object] request
    #   @raise [QueringError] if key not registered with #queries
    #   @raise [QueringError] if multiple records found
    #   @raise [QueringError] if no records found
    #   @return [Object]
    #   @example
    #     Dataset.fetch(name: 'Eld') #=> <Rune name="Eld">
    #   @see #query

    # @!method queries(name, options = {}, &block)
    #   Declare a key for #query
    #   @param name [Symbol] key for #query
    #   @param options [Hash]
    #   @param block [proc { |expression, record| Boolean }]
    #     allows to implement your own logic
    #   @option options [:block, :equality]
    #     factory (`block ? :block : :equality`)
    #     Specifies factory to make a query. Right now it is useless,
    #     but i plan to add special factories which siplifies
    #     queriing array fields and maybe other stuff.
    #     Do not set it now, beacause default value always correct
    #   @option options [Symbol] field (name)
    #     Specifies field to query in equality strategy. Not usefull because
    #     better strategy is to alias field in model instead of doing it here
    #   @raise if factory not found
    #   @see #query
    #   @see Datasetum::QueryRefinements
    #   @example assuming equality factory
    #     queries :name
    #   @example assuming block factory
    #     using Dataset::QueryRefinements
    #     queries :name do |expression, record|
    #       expression.match_any?(record.name)
    #     end
    #   @example same with instance_exec dsl (zero arity required)
    #     using Dataset::QueryRefinements
    #     queries(:name) { expression.match_any? field }
    #   @example complicated usage
    #     using Dataset::QueryRefinements
    #     queries :runes do
    #       field.all? { |x| expression.match_any?(x) }
    #     end
    #     # This will match only records with all runes enumerated in query
  end
end
