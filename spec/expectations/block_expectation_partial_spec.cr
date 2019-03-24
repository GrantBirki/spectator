require "../spec_helper"

describe Spectator::Expectations::BlockExpectationPartial do
  describe "#actual" do
    context "with a label" do
      it "contains the value passed to the constructor" do
        actual = ->{ 777 }
        partial = Spectator::Expectations::BlockExpectationPartial.new(actual, actual.to_s, __FILE__, __LINE__)
        partial.actual.should eq(actual.call)
      end
    end

    context "without a label" do
      it "contains the value passed to the constructor" do
        actual = ->{ 777 }
        partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
        partial.actual.should eq(actual.call)
      end
    end
  end

  describe "#label" do
    context "when provided" do
      it "contains the value passed to the constructor" do
        actual = ->{ 777 }
        label = "lucky"
        partial = Spectator::Expectations::BlockExpectationPartial.new(actual, label, __FILE__, __LINE__)
        partial.label.should eq(label)
      end
    end

    context "when omitted" do
      it "contains \"proc\"" do
        actual = ->{ 777 }
        partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
        partial.label.should match(/proc/i)
      end
    end
  end

  describe "#source_file" do
    it "is the expected value" do
      block = ->{ 42 }
      file = __FILE__
      partial = Spectator::Expectations::BlockExpectationPartial.new(block, file, __LINE__)
      partial.source_file.should eq(file)
    end
  end

  describe "#source_line" do
    it "is the expected value" do
      block = ->{ 42 }
      line = __LINE__
      partial = Spectator::Expectations::BlockExpectationPartial.new(block, __FILE__, line)
      partial.source_line.should eq(line)
    end
  end

  describe "#to" do
    it "reports an expectation" do
      spy = SpyExample.create do
        actual = ->{ 777 }
        expected = 777
        partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
        matcher = Spectator::Matchers::EqualityMatcher.new(expected)
        partial.to(matcher)
      end
      Spectator::Internals::Harness.run(spy)
      spy.harness.expectations.size.should eq(1)
    end

    it "reports multiple expectations" do
      spy = SpyExample.create do
        actual = ->{ 777 }
        expected = 777
        partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
        matcher = Spectator::Matchers::EqualityMatcher.new(expected)
        5.times { partial.to(matcher) }
      end
      Spectator::Internals::Harness.run(spy)
      spy.harness.expectations.size.should eq(5)
    end

    context "with a met condition" do
      it "reports a satisifed expectation" do
        spy = SpyExample.create do
          actual = ->{ 777 }
          expected = 777
          partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
          matcher = Spectator::Matchers::EqualityMatcher.new(expected)
          partial.to(matcher)
        end
        Spectator::Internals::Harness.run(spy)
        spy.harness.expectations.first.satisfied?.should be_true
      end
    end

    context "with an unmet condition" do
      it "reports an unsatisfied expectation" do
        spy = SpyExample.create do
          actual = ->{ 777 }
          expected = 42
          partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
          matcher = Spectator::Matchers::EqualityMatcher.new(expected)
          partial.to(matcher)
        end
        Spectator::Internals::Harness.run(spy)
        spy.harness.expectations.first.satisfied?.should be_false
      end
    end
  end

  {% for method in %i[to_not not_to] %}
    describe "#" + {{method.id.stringify}} do
      it "reports an expectation" do
        spy = SpyExample.create do
          actual = ->{ 777 }
          expected = 777
          partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
          matcher = Spectator::Matchers::EqualityMatcher.new(expected)
          partial.{{method.id}}(matcher)
        end
        Spectator::Internals::Harness.run(spy)
        spy.harness.expectations.size.should eq(1)
      end

      it "reports multiple expectations" do
        spy = SpyExample.create do
          actual = ->{ 777 }
          expected = 42
          partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
          matcher = Spectator::Matchers::EqualityMatcher.new(expected)
          5.times { partial.{{method.id}}(matcher) }
        end
        Spectator::Internals::Harness.run(spy)
        spy.harness.expectations.size.should eq(5)
      end

      context "with a met condition" do
        it "reports an unsatisifed expectation" do
          spy = SpyExample.create do
            actual = ->{ 777 }
            expected = 777
            partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
            matcher = Spectator::Matchers::EqualityMatcher.new(expected)
            partial.{{method.id}}(matcher)
          end
          Spectator::Internals::Harness.run(spy)
          spy.harness.expectations.first.satisfied?.should be_false
        end
      end

      context "with an unmet condition" do
        it "reports an satisfied expectation" do
          spy = SpyExample.create do
            actual = ->{ 777 }
            expected = 42
            partial = Spectator::Expectations::BlockExpectationPartial.new(actual, __FILE__, __LINE__)
            matcher = Spectator::Matchers::EqualityMatcher.new(expected)
            partial.{{method.id}}(matcher)
          end
          Spectator::Internals::Harness.run(spy)
          spy.harness.expectations.first.satisfied?.should be_true
        end
      end
    end
  {% end %}
end
