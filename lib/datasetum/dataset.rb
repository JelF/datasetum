# frozen_string_literal: true

require 'datasetum/service'

module Datasetum
  module Dataset
    extend Forwardable

    def_delegators(
      :__datasetum_service,
      :all, :reset_cache!, :query, :[], :fetch,
      :data_source, :queries, :primary_column, :primary_column=
    )

    private :data_source, :queries, :primary_column, :primary_column=

    # @api private
    private def __datasetum_service
      @__datasetum_service ||= Service.new(self)
    end
  end
end
