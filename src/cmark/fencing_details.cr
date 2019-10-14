module Cmark
  # An inmutable record that represents fencing details of a node with `NodeType::CodeBlock`.
  struct FencingDetails
    getter length : Int32
    getter offset : Int32
    getter character : Char

    def initialize(@length, @offset, backtick = true)
      @character = backtick ? '`' : '~'
    end

    # Returns true if the fencing character is a tilde [`]
    def tilde?
      @character == '~'
    end

    # Returns true if the fencing character is a backtick [~]
    def backtick?
      @character == '`'
    end
  end
end