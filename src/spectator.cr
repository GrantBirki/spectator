require "./spectator/*"

# TODO: Write documentation for `Spectator`
module Spectator
  VERSION = "0.1.0"

  FOO = [] of MacroId

  macro describe(what, source_file = __FILE__, source_line = __LINE__, &block)
    module Spectator
      module Examples
        {{block.body}}
      end
    end
    {% debug %}
  end

  at_exit do
    # TODO
  end
end
