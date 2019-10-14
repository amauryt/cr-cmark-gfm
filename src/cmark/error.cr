module Cmark

  # A generic error class for exceptions not handled by known subclasses.
  class Error <Exception; end

  # An error class for exceptions in setting node accessors with incorrect value/node combinations.
  class NodeSetterError < Error
    def initialize(@message : String)
    end

    def initialize(setter : String, value : String, node : Node)
      @message = <<-MSG
        Failure in `#{setter}` for #{node} with value:
        #{value}
        MSG
    end
  end

  # An error class for exceptions raised while manipulating a document AST.
  class TreeManipulationError < Error; end
end