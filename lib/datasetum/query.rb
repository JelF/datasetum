# frozen_string_literal: true

require 'datasetum/query_refinements'

module Datasetum
  module Query
    # @api private
    class Runner
      attr_reader :expression, :record, :field_name, :field
      alias query expression

      def initialize(builder, expression, record)
        @expression = expression
        @record = record
        return unless builder
        @field_name = builder.options.fetch(:field, builder.name)
        @field = record.public_send(field_name)
      end
    end

    # @api private
    class Built < Struct.new(:filter_proc, :builder, :expression)
      def filter(record)
        if filter_proc.arity.zero?
          runner = Runner.new(builder, expression, record)
          runner.instance_exec(expression, record, &filter_proc)
        else
          filter_proc.call(expression, record)
        end
      end

      def &(other)
        this = self
        Built.new(
          ->(_, record) { this.filter(record) && other.filter(record) }
        )
      end
    end

    # @api private
    TRUE = Built.new(->(*) { true })

    class Builder
      using QueryRefinements

      attr_accessor :name, :options, :block

      def initialize(name, options, &block)
        self.name = name
        self.options = options
        self.block = block
      end

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

      def with_dsl(expression, &block)
        Built.new(block, self, expression)
      end

      def block_runner_factory(expression)
        with_dsl(expression, &block)
      end

      def equality_runner_factory(expression)
        with_dsl(expression) { expression.match_any? [field] }
      end

      def factory
        options.fetch(:factory) do
          block ? :block : :equality
        end
      end
    end
  end
end
