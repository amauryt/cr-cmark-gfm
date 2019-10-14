module Cmark
  # An inmutable record that represents an event returned by `EventIterator`.
  #
  # NOTE: An event with a leaf node always returns true for `#enter?`. See `NodeType` for more information on leaf nodes.
  struct Event
    # The current event node.
    getter node

    protected def initialize(@enter : Bool, @node : Node)

    end

    # Indicates if node can be modified.
    def modifiable?
      (exit? && node.type.container?) || node.type.leaf?
    end

    # Indicates the entering of node.
    def enter?
      @enter
    end

    # Indicates the exiting of node.
    def exit?
      !@enter
    end
  end
end