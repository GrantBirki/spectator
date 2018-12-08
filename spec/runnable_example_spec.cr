require "./spec_helper"

def new_runnable_example(group : Spectator::ExampleGroup? = nil)
  actual_group = group || Spectator::RootExampleGroup.new(Spectator::ExampleHooks.empty)
  PassingExample.new(actual_group, Spectator::Internals::SampleValues.empty).tap do |example|
    actual_group.children = [example.as(Spectator::ExampleComponent)]
  end
end

def run_example(example_type : Spectator::Example.class, hooks : Spectator::ExampleHooks? = nil)
  group = Spectator::RootExampleGroup.new(hooks || Spectator::ExampleHooks.empty)
  run_example(example_type, group)
end

def run_example(example_type : Spectator::Example.class, group : Spectator::ExampleGroup? = nil)
  actual_group = group || Spectator::RootExampleGroup.new(Spectator::ExampleHooks.empty)
  example = example_type.new(actual_group, Spectator::Internals::SampleValues.empty)
  actual_group.children = [example.as(Spectator::ExampleComponent)]
  Spectator::Internals::Harness.run(example)
end

def run_example(hooks : Spectator::ExampleHooks? = nil, &block)
  example = SpyExample.create(hooks || Spectator::ExampleHooks.empty, &block)
  Spectator::Internals::Harness.run(example)
end

describe Spectator::RunnableExample do
  describe "#run" do
    context "with a passing test" do
      it "returns a successful result" do
        run_example(PassingExample).should be_a(Spectator::SuccessfulResult)
      end

      {% for hook_type in %i[before_all before_each] %}
        context "{{hook_type.id}} hooks" do
          it "runs a hook" do
            called = false
            hooks = new_hooks({{hook_type.id}}: ->{ called = true; nil })
            run_example(PassingExample, hooks)
            called.should be_true
          end

          it "runs multiple hooks" do
            call_count = 0
            hooks = new_hooks({{hook_type.id}}: [
              ->{ call_count += 1; nil },
              ->{ call_count += 2; nil },
              ->{ call_count += 3; nil },
            ])
            run_example(PassingExample, hooks)
            call_count.should eq(6)
          end

          it "runs them in the correct order" do
            calls = [] of Symbol
            hooks = new_hooks({{hook_type.id}}: [
              ->{ calls << :a; nil },
              ->{ calls << :b; nil },
              ->{ calls << :c; nil },
            ])
            run_example(PassingExample, hooks)
            calls.should eq(\%i[a b c])
          end

          it "runs parent group hooks" do
            called = false
            hooks = new_hooks({{hook_type.id}}: -> { called = true; nil })
            root = Spectator::RootExampleGroup.new(hooks)
            group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(PassingExample, group)
            called.should be_true
          end

          it "runs parent group hooks first" do
            calls = [] of Symbol
            root_hooks = new_hooks({{hook_type.id}}: -> { calls << :a; nil })
            group_hooks = new_hooks({{hook_type.id}}: -> { calls << :b; nil })
            root = Spectator::RootExampleGroup.new(root_hooks)
            group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(PassingExample, group)
            calls.should eq(\%i[a b])
          end
        end
      {% end %}

      {% for hook_type in %i[after_all after_each] %}
        context "{{hook_type.id}} hooks" do
          it "runs a hook" do
            called = false
            hooks = new_hooks({{hook_type.id}}: ->{ called = true; nil })
            run_example(PassingExample, hooks)
            called.should be_true
          end

          it "runs multiple hooks" do
            call_count = 0
            hooks = new_hooks({{hook_type.id}}: [
              ->{ call_count += 1; nil },
              ->{ call_count += 2; nil },
              ->{ call_count += 3; nil },
            ])
            run_example(PassingExample, hooks)
            call_count.should eq(6)
          end

          it "runs them in the correct order" do
            calls = [] of Symbol
            hooks = new_hooks({{hook_type.id}}: [
              ->{ calls << :a; nil },
              ->{ calls << :b; nil },
              ->{ calls << :c; nil },
            ])
            run_example(PassingExample, hooks)
            calls.should eq(\%i[a b c])
          end

          it "runs parent group hooks" do
            called = false
            hooks = new_hooks({{hook_type.id}}: -> { called = true; nil })
            root = Spectator::RootExampleGroup.new(hooks)
            group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(PassingExample, group)
            called.should be_true
          end

          it "runs parent group hooks last" do
            calls = [] of Symbol
            root_hooks = new_hooks({{hook_type.id}}: -> { calls << :a; nil })
            group_hooks = new_hooks({{hook_type.id}}: -> { calls << :b; nil })
            root = Spectator::RootExampleGroup.new(root_hooks)
            group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(PassingExample, group)
            calls.should eq(\%i[b a])
          end
        end
      {% end %}

      context "around_each hooks" do
        it "runs a hook" do
          called = false
          hooks = new_hooks(around_each: ->(proc : ->) { called = true; proc.call })
          run_example(PassingExample, hooks)
          called.should be_true
        end

        it "runs multiple hooks" do
          call_count = 0
          hooks = new_hooks(around_each: [
            ->(proc : ->) { call_count += 1; proc.call },
            ->(proc : ->) { call_count += 2; proc.call },
            ->(proc : ->) { call_count += 3; proc.call },
          ])
          run_example(PassingExample, hooks)
          call_count.should eq(6)
        end

        it "runs them in the correct order" do
          calls = [] of Symbol
          hooks = new_hooks(around_each: [
            ->(proc : ->) { calls << :a; proc.call },
            ->(proc : ->) { calls << :b; proc.call },
            ->(proc : ->) { calls << :c; proc.call },
          ])
          run_example(PassingExample, hooks)
          calls.should eq(%i[a b c])
        end

        it "runs parent group hooks" do
          called = false
          hooks = new_hooks(around_each: ->(proc : ->) { called = true; proc.call })
          root = Spectator::RootExampleGroup.new(hooks)
          group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
          root.children = [group.as(Spectator::ExampleComponent)]
          run_example(PassingExample, group)
          called.should be_true
        end

        it "runs parent group hooks first" do
          calls = [] of Symbol
          root_hooks = new_hooks(around_each: ->(proc : ->) { calls << :a; proc.call })
          group_hooks = new_hooks(around_each: ->(proc : ->) { calls << :b; proc.call })
          root = Spectator::RootExampleGroup.new(root_hooks)
          group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
          root.children = [group.as(Spectator::ExampleComponent)]
          run_example(PassingExample, group)
          calls.should eq(%i[a b])
        end
      end
    end

    context "with a failing test" do
      it "returns a failed result" do
        run_example(FailingExample).should be_a(Spectator::FailedResult)
      end

      {% for hook_type in %i[before_all before_each] %}
        context "{{hook_type.id}} hooks" do
          it "runs a hook" do
            called = false
            hooks = new_hooks({{hook_type.id}}: ->{ called = true; nil })
            run_example(FailingExample, hooks)
            called.should be_true
          end

          it "runs multiple hooks" do
            call_count = 0
            hooks = new_hooks({{hook_type.id}}: [
              ->{ call_count += 1; nil },
              ->{ call_count += 2; nil },
              ->{ call_count += 3; nil },
            ])
            run_example(FailingExample, hooks)
            call_count.should eq(6)
          end

          it "runs them in the correct order" do
            calls = [] of Symbol
            hooks = new_hooks({{hook_type.id}}: [
              ->{ calls << :a; nil },
              ->{ calls << :b; nil },
              ->{ calls << :c; nil },
            ])
            run_example(FailingExample, hooks)
            calls.should eq(\%i[a b c])
          end

          it "runs parent group hooks" do
            called = false
            hooks = new_hooks({{hook_type.id}}: -> { called = true; nil })
            root = Spectator::RootExampleGroup.new(hooks)
            group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(FailingExample, group)
            called.should be_true
          end

          it "runs parent group hooks first" do
            calls = [] of Symbol
            root_hooks = new_hooks({{hook_type.id}}: -> { calls << :a; nil })
            group_hooks = new_hooks({{hook_type.id}}: -> { calls << :b; nil })
            root = Spectator::RootExampleGroup.new(root_hooks)
            group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(FailingExample, group)
            calls.should eq(\%i[a b])
          end
        end
      {% end %}

      {% for hook_type in %i[after_all after_each] %}
        context "{{hook_type.id}} hooks" do
          it "runs a hook" do
            called = false
            hooks = new_hooks({{hook_type.id}}: ->{ called = true; nil })
            run_example(FailingExample, hooks)
            called.should be_true
          end

          it "runs multiple hooks" do
            call_count = 0
            hooks = new_hooks({{hook_type.id}}: [
              ->{ call_count += 1; nil },
              ->{ call_count += 2; nil },
              ->{ call_count += 3; nil },
            ])
            run_example(FailingExample, hooks)
            call_count.should eq(6)
          end

          it "runs them in the correct order" do
            calls = [] of Symbol
            hooks = new_hooks({{hook_type.id}}: [
              ->{ calls << :a; nil },
              ->{ calls << :b; nil },
              ->{ calls << :c; nil },
            ])
            run_example(FailingExample, hooks)
            calls.should eq(\%i[a b c])
          end

          it "runs parent group hooks" do
            called = false
            hooks = new_hooks({{hook_type.id}}: -> { called = true; nil })
            root = Spectator::RootExampleGroup.new(hooks)
            group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(FailingExample, group)
            called.should be_true
          end

          it "runs parent group hooks last" do
            calls = [] of Symbol
            root_hooks = new_hooks({{hook_type.id}}: -> { calls << :a; nil })
            group_hooks = new_hooks({{hook_type.id}}: -> { calls << :b; nil })
            root = Spectator::RootExampleGroup.new(root_hooks)
            group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(FailingExample, group)
            calls.should eq(\%i[b a])
          end
        end
      {% end %}

      context "around_each hooks" do
        it "runs a hook" do
          called = false
          hooks = new_hooks(around_each: ->(proc : ->) { called = true; proc.call })
          run_example(FailingExample, hooks)
          called.should be_true
        end

        it "runs multiple hooks" do
          call_count = 0
          hooks = new_hooks(around_each: [
            ->(proc : ->) { call_count += 1; proc.call },
            ->(proc : ->) { call_count += 2; proc.call },
            ->(proc : ->) { call_count += 3; proc.call },
          ])
          run_example(FailingExample, hooks)
          call_count.should eq(6)
        end

        it "runs them in the correct order" do
          calls = [] of Symbol
          hooks = new_hooks(around_each: [
            ->(proc : ->) { calls << :a; proc.call },
            ->(proc : ->) { calls << :b; proc.call },
            ->(proc : ->) { calls << :c; proc.call },
          ])
          run_example(FailingExample, hooks)
          calls.should eq(%i[a b c])
        end

        it "runs parent group hooks" do
          called = false
          hooks = new_hooks(around_each: ->(proc : ->) { called = true; proc.call })
          root = Spectator::RootExampleGroup.new(hooks)
          group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
          root.children = [group.as(Spectator::ExampleComponent)]
          run_example(FailingExample, group)
          called.should be_true
        end

        it "runs parent group hooks first" do
          calls = [] of Symbol
          root_hooks = new_hooks(around_each: ->(proc : ->) { calls << :a; proc.call })
          group_hooks = new_hooks(around_each: ->(proc : ->) { calls << :b; proc.call })
          root = Spectator::RootExampleGroup.new(root_hooks)
          group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
          root.children = [group.as(Spectator::ExampleComponent)]
          run_example(FailingExample, group)
          calls.should eq(%i[a b])
        end
      end
    end

    context "with an errored test" do
      it "returns an errored result" do
        run_example(ErroredExample).should be_a(Spectator::ErroredResult)
      end

      {% for hook_type in %i[before_all before_each] %}
        context "{{hook_type.id}} hooks" do
          it "runs a hook" do
            called = false
            hooks = new_hooks({{hook_type.id}}: ->{ called = true; nil })
            run_example(ErroredExample, hooks)
            called.should be_true
          end

          it "runs multiple hooks" do
            call_count = 0
            hooks = new_hooks({{hook_type.id}}: [
              ->{ call_count += 1; nil },
              ->{ call_count += 2; nil },
              ->{ call_count += 3; nil },
            ])
            run_example(ErroredExample, hooks)
            call_count.should eq(6)
          end

          it "runs them in the correct order" do
            calls = [] of Symbol
            hooks = new_hooks({{hook_type.id}}: [
              ->{ calls << :a; nil },
              ->{ calls << :b; nil },
              ->{ calls << :c; nil },
            ])
            run_example(ErroredExample, hooks)
            calls.should eq(\%i[a b c])
          end

          it "runs parent group hooks" do
            called = false
            hooks = new_hooks({{hook_type.id}}: -> { called = true; nil })
            root = Spectator::RootExampleGroup.new(hooks)
            group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(ErroredExample, group)
            called.should be_true
          end

          it "runs parent group hooks first" do
            calls = [] of Symbol
            root_hooks = new_hooks({{hook_type.id}}: -> { calls << :a; nil })
            group_hooks = new_hooks({{hook_type.id}}: -> { calls << :b; nil })
            root = Spectator::RootExampleGroup.new(root_hooks)
            group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(ErroredExample, group)
            calls.should eq(\%i[a b])
          end
        end
      {% end %}

      {% for hook_type in %i[after_all after_each] %}
        context "{{hook_type.id}} hooks" do
          it "runs a hook" do
            called = false
            hooks = new_hooks({{hook_type.id}}: ->{ called = true; nil })
            run_example(ErroredExample, hooks)
            called.should be_true
          end

          it "runs multiple hooks" do
            call_count = 0
            hooks = new_hooks({{hook_type.id}}: [
              ->{ call_count += 1; nil },
              ->{ call_count += 2; nil },
              ->{ call_count += 3; nil },
            ])
            run_example(ErroredExample, hooks)
            call_count.should eq(6)
          end

          it "runs them in the correct order" do
            calls = [] of Symbol
            hooks = new_hooks({{hook_type.id}}: [
              ->{ calls << :a; nil },
              ->{ calls << :b; nil },
              ->{ calls << :c; nil },
            ])
            run_example(ErroredExample, hooks)
            calls.should eq(\%i[a b c])
          end

          it "runs parent group hooks" do
            called = false
            hooks = new_hooks({{hook_type.id}}: -> { called = true; nil })
            root = Spectator::RootExampleGroup.new(hooks)
            group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(ErroredExample, group)
            called.should be_true
          end

          it "runs parent group hooks last" do
            calls = [] of Symbol
            root_hooks = new_hooks({{hook_type.id}}: -> { calls << :a; nil })
            group_hooks = new_hooks({{hook_type.id}}: -> { calls << :b; nil })
            root = Spectator::RootExampleGroup.new(root_hooks)
            group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
            root.children = [group.as(Spectator::ExampleComponent)]
            run_example(ErroredExample, group)
            calls.should eq(\%i[b a])
          end
        end
      {% end %}

      context "around_each hooks" do
        it "runs a hook" do
          called = false
          hooks = new_hooks(around_each: ->(proc : ->) { called = true; proc.call })
          run_example(ErroredExample, hooks)
          called.should be_true
        end

        it "runs multiple hooks" do
          call_count = 0
          hooks = new_hooks(around_each: [
            ->(proc : ->) { call_count += 1; proc.call },
            ->(proc : ->) { call_count += 2; proc.call },
            ->(proc : ->) { call_count += 3; proc.call },
          ])
          run_example(ErroredExample, hooks)
          call_count.should eq(6)
        end

        it "runs them in the correct order" do
          calls = [] of Symbol
          hooks = new_hooks(around_each: [
            ->(proc : ->) { calls << :a; proc.call },
            ->(proc : ->) { calls << :b; proc.call },
            ->(proc : ->) { calls << :c; proc.call },
          ])
          run_example(ErroredExample, hooks)
          calls.should eq(%i[a b c])
        end

        it "runs parent group hooks" do
          called = false
          hooks = new_hooks(around_each: ->(proc : ->) { called = true; proc.call })
          root = Spectator::RootExampleGroup.new(hooks)
          group = Spectator::NestedExampleGroup.new("what", root, Spectator::ExampleHooks.empty)
          root.children = [group.as(Spectator::ExampleComponent)]
          run_example(ErroredExample, group)
          called.should be_true
        end

        it "runs parent group hooks first" do
          calls = [] of Symbol
          root_hooks = new_hooks(around_each: ->(proc : ->) { calls << :a; proc.call })
          group_hooks = new_hooks(around_each: ->(proc : ->) { calls << :b; proc.call })
          root = Spectator::RootExampleGroup.new(root_hooks)
          group = Spectator::NestedExampleGroup.new("what", root, group_hooks)
          root.children = [group.as(Spectator::ExampleComponent)]
          run_example(ErroredExample, group)
          calls.should eq(%i[a b])
        end
      end
    end

    context "when an error is raised in a before_all hook" do
      it "raises the exception" do
        hooks = new_hooks(before_all: ->{ raise "oops"; nil })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
      end

      it "doesn't run the test code" do
        called = false
        hooks = new_hooks(before_all: ->{ raise "oops"; nil })
        expect_raises(Exception) do
          run_example(hooks) do
            called = true
          end
        end
        called.should be_false
      end

      it "doesn't run any additional before_all hooks" do
        called = false
        hooks = new_hooks(before_all: [
          ->{ raise "oops"; nil },
          ->{ called = true; nil },
        ])
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should be_false
      end

      it "doesn't run any additional hooks" do
        called = :none
        hooks = new_hooks(
          before_all: ->{ raise "oops"; nil },
          before_each: ->{ called = :before_each; nil },
          after_all: ->{ called = :after_all; nil },
          after_each: ->{ called = :after_each; nil },
          around_each: ->(proc : ->) { called = :around_each; proc.call })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should eq(:none)
      end
    end

    context "when an error is raised in a before_each hook" do
      it "raises the exception" do
        hooks = new_hooks(before_each: ->{ raise "oops"; nil })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
      end

      it "doesn't run the test code" do
        called = false
        hooks = new_hooks(before_each: ->{ raise "oops"; nil })
        expect_raises(Exception) do
          run_example(hooks) do
            called = true
          end
        end
        called.should be_false
      end

      it "doesn't run any additional before_each hooks" do
        called = false
        hooks = new_hooks(before_each: [
          ->{ raise "oops"; nil },
          ->{ called = true; nil },
        ])
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should be_false
      end

      it "doesn't run any additional hooks" do
        called = :none
        hooks = new_hooks(
          before_each: ->{ raise "oops"; nil },
          after_all: ->{ called = :after_all; nil },
          after_each: ->{ called = :after_each; nil },
          around_each: ->(proc : ->) { called = :around_each; proc.call })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should eq(:none)
      end
    end

    context "when an error is raised in an after_all hook" do
      it "raises the exception" do
        hooks = new_hooks(before_all: ->{ raise "oops"; nil })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
      end

      it "doesn't run any additional after_all hooks" do
        called = false
        hooks = new_hooks(before_all: [
          ->{ raise "oops"; nil },
          ->{ called = true; nil },
        ])
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should be_false
      end
    end

    context "when an error is raised in an after_each hook" do
      it "raises the exception" do
        hooks = new_hooks(after_each: ->{ raise "oops"; nil })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
      end

      it "doesn't run any additional after_each hooks" do
        called = false
        hooks = new_hooks(after_each: [
          ->{ raise "oops"; nil },
          ->{ called = true; nil },
        ])
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should be_false
      end

      it "doesn't run any additional hooks" do
        called = :none
        hooks = new_hooks(
          before_all: ->{ nil },
          before_each: ->{ nil },
          after_all: ->{ called = :after_all; nil },
          after_each: ->{ raise "oops"; nil },
          around_each: ->(proc : ->) { called = :around_each; proc.call })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should eq(:none)
      end
    end

    context "when an error is raised in an around_each hook" do
      it "raises the exception" do
        hooks = new_hooks(around_each: ->(proc : ->) { raise "oops"; proc.call })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
      end

      it "doesn't run the test code" do
        called = false
        hooks = new_hooks(around_each: ->(proc : ->) { raise "oops"; proc.call })
        expect_raises(Exception) do
          run_example(hooks) do
            called = true
          end
        end
        called.should be_false
      end

      it "doesn't run any additional around_each hooks" do
        called = false
        hooks = new_hooks(around_each: [
          ->(proc : ->) { raise "oops"; proc.call },
          ->(proc : ->) { called = true; proc.call },
        ])
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should be_false
      end

      it "doesn't run any additional hooks" do
        called = :none
        hooks = new_hooks(
          after_all: ->{ called = :after_all; nil },
          after_each: ->{ called = :after_each; nil },
          around_each: ->(proc : ->) { raise "oops"; proc.call })
        expect_raises(Exception) do
          run_example(PassingExample, hooks)
        end
        called.should eq(:none)
      end
    end
  end

  describe "#finished?" do
    it "is initially false" do
      new_runnable_example.finished?.should be_false
    end

    it "is true after #run is called" do
      example = new_runnable_example
      Spectator::Internals::Harness.run(example)
      example.finished?.should be_true
    end
  end

  describe "#group" do
    it "is the expected value" do
      group = Spectator::RootExampleGroup.new(Spectator::ExampleHooks.empty)
      example = new_runnable_example(group)
      example.group.should eq(group)
    end
  end

  describe "#example_count" do
    it "is one" do
      new_runnable_example.example_count.should eq(1)
    end
  end

  describe "#[]" do
    it "returns self" do
      example = new_runnable_example
      example[0].should eq(example)
    end
  end

  describe "#to_s" do
    it "contains #what" do
      example = new_runnable_example
      example.to_s.should contain(example.what)
    end

    it "contains the group's #what" do
      root = Spectator::RootExampleGroup.new(Spectator::ExampleHooks.empty)
      group = Spectator::NestedExampleGroup.new("the parent", root, Spectator::ExampleHooks.empty)
      root.children = [group.as(Spectator::ExampleComponent)]
      example = new_runnable_example(group)
      example.to_s.should contain(group.what)
    end
  end
end
