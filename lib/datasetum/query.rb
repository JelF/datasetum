# frozen_string_literal: true

require 'datasetum/query_refinements'

module Datasetum
  # Collection of classes to go from query defenition to application
  module Query
    # Provides dsl for #queries block
    # @see Datasetum::Dataset#queries
    class Runner
      # @return [Object]
      #  expression passed as value into Datasetum::Dataset#query
      # @see Datasetum::Dataset#query
      attr_reader :expression

      # @return [Object] record currently matching
      attr_reader :record

      # @return [Symbol] name of field set in queries
      # @see Datasetum::Dataset#queries
      attr_reader :field_name

      # @return [Object] value of field set in queries
      # @see Datasetum::Dataset#queries
      attr_reader :field

      alias query expression

      # @api private
      # @param [Query::Builder] builder set in #queries
      # @param [Object] expression passed as value into #query
      # @param [Object] record currently matching
      # @see Datasetum::Dataset#query
      # @see Datasetum::Dataset#queries
      def initialize(builder, expression, record)
        @expression = expression
        @record = record
        return unless builder
        @field_name = builder.options.fetch(:field, builder.name)
        @field = record.public_send(field_name)
      end
    end

    # result of Query::Builder#build
    # @api private
    # @see Query::Builder#build
    class Built < Struct.new(:filter_proc, :builder, :expression)
      # @!attribute filter_proc
      #   @return [proc { |expression, record| Boolean }]

      # @!attribute builder
      #   @return [Query::Builder]

      # @!attribute expression
      #   @return [Object] expresion bound in Query::Builder#build

      # @param [Object] record record to match
      # @return [true] if matches
      # @return [false] otherwise
      def filter(record)
        if filter_proc.arity.zero?
          runner = Runner.new(builder, expression, record)
          runner.instance_exec(expression, record, &filter_proc)
        else
          filter_proc.call(expression, record)
        end
      end

      # join to built queries into one
      # @param [Query::Built] other
      # @return [Query::Built]
      def &(other)
        this = self
        Built.new(
          ->(_, record) { this.filter(record) && other.filter(record) }
        )
      end
    end

    # empty query
    # @api private
    TRUE = Built.new(->(*) { true })

    # Builder for queries
    # @api private
    # @see Datasetum::Dataset#queries
    class Builder
      using QueryRefinements

      # @return [Symbol] name of field
      attr_accessor :name

      # @return [Hash] options
      attr_accessor :options

      # @return [proc { |expresion, record| Boolean }]
      attr_accessor :block

      # @param [Symbol] name field name
      # @param [Hash] options
      # @param [proc { |expresion, record| Boolean }] block
      # @option options [:block, :equality]
      #   factory (`block ? :block : :equality`)
      #   Specifies factory to make a query. Right now it is useless,
      #   but i plan to add special factories which siplifies
      #   queriing array fields and maybe other stuff.
      #   Do not set it now, beacause default value always correct
      # @option options [Symbol] field (name)
      #   Specifies field to query in equality strategy. Not usefull because
      #   better strategy is to alias field in model instead of doing it here
      def initialize(name, options, &block)
        self.name = name
        self.options = options
        self.block = block
      end

      # bind expression to query builder
      # @param [Object] expression
      # @return [Query::Built]
      def build(expression)
        case factory
        when :block
          block_runner_factory(expression)
        when :equality
          equality_runner_factory(expression)
        else
          raise "unknown factory #{factory}"
        end
      end

      private

      # utility method to allow Runner dsl in factory defenitions
      # @param [Object] expression
      # @return [Query::Built]
      def with_dsl(expression, &block)
        Built.new(block, self, expression)
      end

      # Factory for block strategy
      # @param [Object] expression
      # @return [Query::Built]
      def block_runner_factory(expression)
        with_dsl(expression, &block)
      end

      # Factory for equality strategy
      # @param [Object] expression
      # @return [Query::Built]
      # @see Datasetum::QueryRefinements
      def equality_runner_factory(expression)
        with_dsl(expression) { expression.match_any? [field] }
      end

      # @return [Symbol] factory code to use in #build
      def factory
        options.fetch(:factory) do
          block ? :block : :equality
        end
      end
    end
  end
end
