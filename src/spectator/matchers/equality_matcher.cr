require "./value_matcher"

module Spectator::Matchers
  # Common matcher that tests whether two values equal each other.
  # The values are compared with the == operator.
  struct EqualityMatcher(ExpectedType) < ValueMatcher(ExpectedType)
    # Determines whether the matcher is satisfied with the value given to it.
    private def match?(actual)
      actual == expected
    end

    # Determines whether the matcher is satisfied with the partial given to it.
    def match(partial, negated = false)
      values = ExpectedActual.new(partial, self)
      MatchData.new(match?(values.actual), values)
    end

    # Match data specific to this matcher.
    private struct MatchData(ExpectedType, ActualType) < MatchData
      # Creates the match data.
      def initialize(matched, @values : ExpectedActual(ExpectedType, ActualType))
        super(matched)
      end

      # Information about the match.
      def named_tuple
        {
          expected: NegatableMatchDataValue.new(@values.expected),
          actual:   @values.actual,
        }
      end

      # Describes the condition that satisfies the matcher.
      # This is informational and displayed to the end-user.
      def message
        "#{@values.actual_label} is #{@values.expected_label} (using ==)"
      end

      # Describes the condition that won't satsify the matcher.
      # This is informational and displayed to the end-user.
      def negated_message
        "#{@values.actual_label} is not #{@values.expected_label} (using ==)"
      end
    end
  end
end
