module Spectator::Expectations
  # Ties together a partial, matcher, and their outcome.
  class Expectation
    # Populates the base portiion of the expectation with values.
    # The *negated* flag should be true if the expectation is inverted.
    # The *match_data* is the value returned by `Spectator::Matcher#match`
    # when the expectation was evaluated.
    # The *negated* flag and `MatchData#matched?` flag
    # are mutually-exclusive in this context.
    def initialize(@match_data : Spectator::Matchers::MatchData, @negated : Bool)
    end

    # Indicates whether the expectation was satisifed.
    # This is true if:
    # - The matcher was satisified and the expectation is not negated.
    # - The matcher wasn't satisfied and the expectation is negated.
    def satisfied?
      @match_data.matched? ^ @negated
    end

    # Information about the match.
    # Returned value and type will something that has key-value pairs (like a `NamedTuple`).
    def values
      @match_data.values.tap do |labeled_values|
        if @negated
          labeled_values.each do |labeled_value|
            value = labeled_value.value
            value.negate if value.responds_to?(:negate)
          end
        end
      end
    end

    # Text that indicates the condition that must be met for the expectation to be satisifed.
    def expected_message
      @negated ? @match_data.negated_message : @match_data.message
    end

    # Text that indicates what the outcome was.
    def actual_message
      @match_data.matched? ? @match_data.message : @match_data.negated_message
    end

    # Creates the JSON representation of the expectation.
    def to_json(json : ::JSON::Builder)
      json.object do
        json.field("satisfied") { satisfied?.to_json(json) }
        json.field("expected") { expected_message.to_json(json) }
        json.field("actual") { actual_message.to_json(json) }
        json.field("values") do
          json.object do
            values.each do |labeled_value|
              json.field(labeled_value.label, labeled_value.value.to_s)
            end
          end
        end
      end
    end
  end
end
