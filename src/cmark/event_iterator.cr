require "./lib_cmark"
module Cmark

  # An iterator that walks through a tree of nodes, starting from a root node, returning an `Event` with one node at a time,
  # together with information about whether the node is being entered or exited, and if it is modifiable.
  #
  # The iterator will first descend to a child node (returning an ENTER `Event`),
  # if there is one.
  # When there is no child, the iterator will go to the next sibling.
  # When there is no next sibling, the iterator will return to the parent (but returning an EXIT `Event`).
  # The iterator will stop after it reaches the root node again on exit.
  #
  # One natural application is an HTML renderer, where an ENTER event outputs an open tag and an EXIT
  # event outputs a close tag.
  # An iterator might also be used to transform an AST in some systematic way, for example, turning all
  # level-3 headings into regular paragraphs.
  #
  # NOTE: Nodes can be modified only after an EXIT event or an ENTER event for leaf nodes. The convenience
  # method `Event#modifiable?` checks that these conditions are met.
  class EventIterator
    include Iterator(Event)

    def initialize(@root : Node)
      @iter_p = LibCmark.cmark_iter_new(@root.node_p)
      # The current node and event type are undefined until cmark_iter_next is called for  the  first  time.
      @initial_lib_event_type = LibCmark.cmark_iter_next(@iter_p)
    end

    # :nodoc:
    def finalize
      LibCmark.cmark_iter_free(@iter_p)
    end

    # Returns the next node event in this iterator, or `Iterator::Stop::INSTANCE` if there are no more events.
    def next
      type = LibCmark.cmark_iter_get_event_type(@iter_p)
      if type.cmark_event_done? || type.cmark_event_none?
        stop
      else
        node = Node.new(LibCmark.cmark_iter_get_node(@iter_p))
        LibCmark.cmark_iter_next(@iter_p)
        Event.new(type.cmark_event_enter?, node)
      end
    end

    # Rewinds the iterator to its original state.
    def rewind
      root_p = LibCmark.cmark_iter_get_root(@iter_p)
      LibCmark.cmark_iter_reset(@iter_p, root_p, @initial_lib_event_type)
      self
    end

    # Returns an iterator with all the nodes in the order in which can be modified.
    def modifiable_node_iterator : Iterator(Node)
      (self.select &.modifiable?).map &.node
    end
  end
end