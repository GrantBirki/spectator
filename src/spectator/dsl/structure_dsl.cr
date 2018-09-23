require "../example_group"

module Spectator
  module DSL
    module StructureDSL

      def initialize(locals : Hash(Symbol, ::Spectator::ValueWrapper))
      end

      macro describe(what, &block)
        context({{what}}) {{block}}
      end

      macro context(what, &block)
        module Group%group
          include {{@type.id}}

          {% if what.is_a?(Path) || what.is_a?(Generic) %}
            _spectator_described_class {{what}}
          {% end %}

          ::Spectator::DSL::Builder.start_group(
            {{what.is_a?(StringLiteral) ? what : what.stringify}}
          )

          {{block.body}}

          ::Spectator::DSL::Builder.end_group
        end
      end

      macro given(collection, &block)
        module Group%group
          include {{@type.id}}

          def %collection
            {{collection}}
          end

          @%wrapper : ::Spectator::ValueWrapper

          def {{block.args.empty? ? "value".id : block.args.first}}
            @%wrapper.as(::Spectator::TypedValueWrapper(typeof(%collection.first))).value
          end

          def initialize(locals : Hash(Symbol, ::Spectator::ValueWrapper))
            super
            @%wrapper = locals[:%group]
          end

          _spectator_given_collection Collection%collection, %to_a, %collection
          %to_a = Collection%collection.new.%to_a

          ::Spectator::DSL::Builder.start_given_group(
            {{collection.stringify}},
            %to_a,
            :%group
          )

          {{block.body}}

          ::Spectator::DSL::Builder.end_group
        end
      end

      macro subject(&block)
        let(:subject) {{block}}
      end

      macro let(name, &block)
        let!(%value) {{block}}

        @%wrapper : ::Spectator::ValueWrapper?

        def {{name.id}}
          if (wrapper = @%wrapper)
            wrapper.unsafe_as(::Spectator::TypedValueWrapper(typeof(%value))).value
          else
            %value.tap do |value|
              @%wrapper = ::Spectator::TypedValueWrapper(typeof(%value)).new(value)
            end
          end
        end
      end

      macro let!(name, &block)
        def {{name.id}}
          {{block.body}}
        end
      end

      macro before_all(&block)
        ::Spectator::DSL::Builder.add_before_all_hook {{block}}
      end

      macro before_each(&block)
        ::Spectator::DSL::Builder.add_before_each_hook {{block}}
      end

      macro after_all(&block)
        ::Spectator::DSL::Builder.add_after_all_hook {{block}}
      end

      macro after_each(&block)
        ::Spectator::DSL::Builder.add_after_each_hook {{block}}
      end

      macro around_each(&block)
        ::Spectator::DSL::Builder.add_around_each_hook {{block}}
      end

      def include_examples
        raise NotImplementedError.new("Spectator::DSL#include_examples")
      end

      macro it(description, &block)
        _spectator_example_wrapper(Wrapper%example, %run) {{block}}

        _spectator_example(Example%example, Wrapper%example, ::Spectator::RunnableExample, {{description}}) do
          protected def run_instance
            @instance.%run
          end
        end

        ::Spectator::DSL::Builder.add_example(Example%example)
      end

      macro pending(description, &block)
        _spectator_example_wrapper(Wrapper%example, %run) {{block}}

        _spectator_example(Example%example, Wrapper%example, ::Spectator::PendingExample, {{description}})

        ::Spectator::DSL::Builder.add_example(Example%example)
      end

      def it_behaves_like
        raise NotImplementedError.new("Spectator::DSL#it_behaves_like")
      end

      macro _spectator_described_class(what)
        def described_class
          {{what}}.tap do |thing|
            raise "#{thing} must be a type name to use #described_class or #subject,\
             but it is a #{typeof(thing)}" unless thing.is_a?(Class)
          end
        end

        _spectator_implicit_subject
      end

      macro _spectator_implicit_subject
        def subject
          described_class.new
        end
      end

      macro _spectator_given_collection(class_name, to_a_method_name, collection_method_name)
        class {{class_name.id}}
          include {{@type.id}}

          def {{to_a_method_name.id}}
            Array(::Spectator::ValueWrapper).new.tap do |array|
              {{collection_method_name.id}}.each do |item|
                array << ::Spectator::TypedValueWrapper(typeof(item)).new(item)
              end
            end
          end
        end
      end

      macro _spectator_example_wrapper(class_name, run_method_name, &block)
        class {{class_name.id}}
          include ::Spectator::DSL::ExampleDSL
          include {{@type.id}}

          def initialize(locals : Hash(Symbol, ::Spectator::ValueWrapper))
            super
          end

          def {{run_method_name.id}}
            {{block.body}}
          end
        end
      end

      macro _spectator_example(example_class_name, wrapper_class_name, base_class, description, &block)
        class {{example_class_name.id}} < {{base_class.id}}
          def initialize(group : ::Spectator::ExampleGroup, locals : Hash(Symbol, ::Spectator::ValueWrapper))
            super
            @instance = {{wrapper_class_name.id}}.new(locals)
          end

          {% if block.is_a?(Block) %}
            {{block.body}}
          {% end %}

          def description
            {{description.is_a?(StringLiteral) ? description : description.stringify}}
          end
        end
      end
    end
  end
end
