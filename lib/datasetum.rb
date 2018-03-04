# frozen_string_literal: true

require 'datasetum/version'
require 'datasetum/query_refinements'
require 'datasetum/dataset'

# Datasetum designed to operate with big immutable collections. In comparsion
# with sqlite3 it is musch slower, hovewer it allows to write ruby-only code
# whith much DSLs.
# @see Datasetum::Dataset
#   Datasetum::Dataset to start
# @see Datasetum::QueringError
#   Datasetum::QueringError to handle errors i raise
# @see Datasetum::Query::Runner
#   Datasetum::Query::Runner to write block queries defenition with dsl
# @see Datasetum::QueryRefinements
#   Datasetum::QueryRefinements to simplify it
module Datasetum
end
