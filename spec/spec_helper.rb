# frozen_string_literal: true

require 'bundler/setup'
require 'datasetum'
Bundler.require(:runtime, :development)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  Pathname.new(__FILE__).join('..', '..', 'tmp').mkpath

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = 'tmp/spec_failures'
  config.disable_monkey_patching!

  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 2
  config.order = :random
  Kernel.srand config.seed
end
