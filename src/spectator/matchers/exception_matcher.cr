require "../test_value"
require "./failed_match_data"
require "./matcher"
require "./successful_match_data"

module Spectator::Matchers
  # Matcher that tests whether an exception is raised.
  struct ExceptionMatcher(ExceptionType, ExpectedType) < Matcher
    private getter expected

    def initialize
      @expected = TestValue.new(nil, ExceptionType.to_s)
    end

    def initialize(@expected : TestValue(ExpectedType))
    end

    def description
      if (message = @expected)
        "raises #{ExceptionType} with message #{message}"
      else
        "raises #{ExceptionType}"
      end
    end

    def match(actual)
      exception = capture_exception { actual.value }
      if exception.nil?
        FailedMatchData.new("#{actual.label} did not raise", expected: ExceptionType.inspect)
      else
        if exception.is_a?(ExceptionType)
          if (value = expected.value).nil?
            SuccessfulMatchData.new
          else
            if value === exception.message
              SuccessfulMatchData.new
            else
              FailedMatchData.new("#{actual.label} raised #{exception.class}, but the message is not #{expected.label}",
                "expected type": ExceptionType.inspect,
                "actual type": exception.class.inspect,
                "expected message": value.inspect,
                "actual message": exception.message.to_s
              )
            end
          end
        else
          FailedMatchData.new("#{actual.label} did not raise #{ExceptionType}",
            expected: ExceptionType.inspect,
            actual: exception.class.inspect
          )
        end
      end
    end

    def negated_match(actual)
      exception = capture_exception { actual.value }
      if exception.nil?
        SuccessfulMatchData.new
      else
        if exception.is_a?(ExceptionType)
          if (value = expected.value).nil?
            FailedMatchData.new("#{actual.label} raised #{exception.class}",
              expected: "Not #{ExceptionType}",
              actual: exception.class.inspect
            )
          else
            if value === exception.message
              FailedMatchData.new("#{actual.label} raised #{exception.class} with message matching #{expected.label}",
                "expected type": ExceptionType.inspect,
                "actual type": exception.class.inspect,
                "expected message": value.inspect,
                "actual message": exception.message.to_s
              )
            else
              SuccessfulMatchData.new
            end
          end
        else
          SuccessfulMatchData.new
        end
      end
    end

    # Runs a block of code and returns the exception it threw.
    # If no exception was thrown, *nil* is returned.
    private def capture_exception
      exception = nil
      begin
        yield
      rescue ex
        exception = ex
      end
      exception
    end

    # Creates a new exception matcher with no message check.
    def self.create(exception_type : T.class, label : String) forall T
      ExceptionMatcher(T, Nil).new
    end

    # Creates a new exception matcher with a message check.
    def self.create(value, label : String)
      expected = TestValue.new(value, label)
      ExceptionMatcher(Exception, typeof(value)).new(expected)
    end

    # Creates a new exception matcher with a type and message check.
    def self.create(exception_type : T.class, value, label : String) forall T
      expected = TestValue.new(value, label)
      ExceptionMatcher(T, typeof(value)).new(expected)
    end
  end
end
