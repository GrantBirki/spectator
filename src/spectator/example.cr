module Spectator
  abstract class Example
    macro is_expected
      expect(subject)
    end
    
    abstract def run
  end
end
