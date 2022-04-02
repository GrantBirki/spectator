require "./typed_stub"
require "./value_stub"

module Spectator
  # Stub that does nothing and returns nil.
  class NullStub < TypedStub(Nil)
    # Invokes the stubbed implementation.
    def call(_call : MethodCall) : Nil
    end
  end
end
