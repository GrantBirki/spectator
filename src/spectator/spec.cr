require "./config"
require "./example_group"
require "./spec/*"

module Spectator
  # Contains examples to be tested and configuration for running them.
  class Spec
    # Creates the spec.
    # The *root* is the top-most example group.
    # All examples in this group and groups nested under are candidates for execution.
    # The *config* provides settings controlling how tests will be executed.
    def initialize(@root : ExampleGroup, @config : Config)
    end

    # Runs all selected examples and returns the results.
    # True will be returned if the spec ran successfully,
    # or false if there was at least one failure.
    def run : Bool
      runner = Runner.new(examples, @config.formatter, @config.run_flags)
      runner.run
    end

    # Selects and shuffles the examples that should run.
    private def examples
      iterator = @config.iterator(@root)
      iterator.to_a.tap do |examples|
        @config.shuffle!(examples)
      end
    end
  end
end
