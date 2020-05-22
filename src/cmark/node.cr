require "./lib_cmark"
require "./node_type"

module Cmark
  # A node is a construct of the abstract syntax tree (AST) for a given markdown content.
  #
  # At the very minimum every node has a `NodeType` —available via `#type`— even when invalid.
  # However, given that each type of node has a set of required properties
  # —which if are not set may lead to unintended behavior—
  # all initializers of `Node` are protected. Nodes can be created
  # in a safer manner either with the module `NodeMaker`, or with the parsing
  # methods of the module`Cmark` (which return a node with `NodeType::Document`).
  #
  # Instance methods can be grouped into:
  #
  # - Tree traversal
  #   - `#next`
  #   - `#previous`
  #   - `#parent`
  #   - `#grandparent`
  #   - `#first_child`
  #   - `#last_child`
  #   - `#children`
  #
  # - Accessors
  #   - `#type`
  #   - `#literal`
  #   - `#literal=`
  #   - `#heading_level`
  #   - `#heading_level=`
  #   - `#list_type`
  #   - `#list_type=`
  #   - `#list_delim`
  #   - `#list_delim=`
  #   - `#list_start`
  #   - `#list_start=`
  #   - `#list_tight?`
  #   - `#list_tight=`
  #   - `#fence_info`
  #   - `#fence_info=`
  #   - `#fencing_details`
  #   - `#fencing_details=`
  #   - `#url`
  #   - `#url=`
  #   - `#title`
  #   - `#title=`
  #   - `#on_enter`
  #   - `#on_enter=`
  #   - `#on_exit`
  #   - `#on_exit=`
  #   - `#user_data`
  #   - `#user_data=`
  #   - `#start_line`
  #   - `#end_line`
  #   - `#start_column`
  #   - `#end_column`
  #   - `#autolink?`
  #   - `#table_string_content`
  #   - `#table_string_content=`
  #   - `#table_columns`
  #   - `#table_columns=`
  #   - `#table_alignments`
  #   - `#table_alignments=`
  #   - `#table_row_header?`
  #   - `#table_row_header=`
  #   - `#tasklist_item?`
  #   - `#tasklist_item=`
  #   - `#tasklist_item_checked?`
  #   - `#tasklist_item_checked=`
  #
  # - Tree manipulation
  #   - `#unlink`
  #   - `#insert_before`
  #   - `#insert_after`
  #   - `#replace_with`
  #   - `#prepend_child`
  #   - `#append_child`
  #   - `#consolidate_text_nodes`
  #
  # - Rendering
  #   - `#render_xml`
  #   - `#render_html`
  #   - `#render_plaintext`
  #   - `#render_commonmark`
  #   - `#render_latex`
  #   - `#render_man`
  #
  # - Equality
  #   - `#==`
  #
  # - Containment
  #   - `#can_contain?`
  #
  # NOTE: The `Node` class is a thin wrapper for the node struct of the
  # underlying cmark-gfm C library, as such, **familiarity with the
  # [GFM Spec](https://github.github.com/gfm/) is required for advanced
  # node creation, processing, and rendering**.
  class Node
    # Keeps track of the number of instances to free LibCmark::CmarkNode pointers.
    @@instances = Hash(Pointer(Cmark::LibCmark::CmarkNode), UInt32).new(0)

    protected getter node_p : LibCmark::CmarkNode*

    private macro define_traversal_methods(*names)
      {% for name in names %}
        # Returns the {{name.id}} node of this node.
        def {{name.id}} : Node?
          {{name.id}}_p = LibCmark.cmark_node_{{name.id}}(@node_p)
          {{name.id}}_p.null? ? nil : Node.new({{name.id}}_p)
        end
      {% end %}
    end

    private macro setter_return_value
      {% argument_name = @def.args[0].name %}
      raise NodeSetterError.new("{{@def.name}}", {{argument_name}}.to_s, self) if result.zero?
      {{argument_name}}
    end

    protected def initialize(@node_p)
      @@instances[@node_p] += 1
    end

    protected def initialize(type : LibCmark::NodeType)
      @node_p = LibCmark.cmark_node_new(type)
      @@instances[@node_p] += 1
    end

    # :nodoc:
    def finalize
      @@instances[@node_p] -= 1
      if @@instances[@node_p].zero?
        @@instances.delete(@node_p)
        LibCmark.cmark_node_free(@node_p) if LibCmark.cmark_node_parent(@node_p).null?
      end
    end

    # === Traversal

    define_traversal_methods :next, :previous, :parent, :first_child, :last_child

    # Returns the grandparent node of this node.
    def grandparent : Node?
      parent_p = LibCmark.cmark_node_parent(@node_p)
      unless parent_p.null?
        grandparent_p = LibCmark.cmark_node_parent(parent_p)
        Node.new(grandparent_p) unless grandparent_p.null?
      end
    end

    # Returns children nodes or an empty array if there are none.
    def children : Array(Node)
      children = [] of Node
      current_p = LibCmark.cmark_node_first_child(@node_p)
      last_child_p = LibCmark.cmark_node_last_child(@node_p)
      while current_p
        children.push Node.new(current_p) if LibCmark.cmark_node_parent(current_p) == @node_p
        break if current_p == last_child_p
        current_p = LibCmark.cmark_node_next(current_p)
      end
      children
    end

    # === Accessors

    # Returns the type of node.
    def type : NodeType
      unless type = NodeType.from_value?(LibCmark.cmark_node_get_type(@node_p).value)
        type_name = self.type_original_string
        type_name = "table_row" if type_name == "table_header"
        type = NodeType.parse(type_name)
      end
      type
    end

    # Returns the underlying C library type of node as a string representation, or "<unknown>".
    protected def type_original_string : String
      String.new(LibCmark.cmark_node_get_type_string(@node_p))
    end

    # Returns the literal string contents of node, or an empty string if none is set.
    def literal : String?
      result = LibCmark.cmark_node_get_literal(@node_p)
      result.null? ? "" : String.new(result)
    end

    # Sets the literal string contents of node; on failure it raises `NodeSetterError`.
    def literal=(literal : String) : String
      result = LibCmark.cmark_node_set_literal(@node_p, literal)
      setter_return_value
    end

    # Returns the heading level of node, or 0 if node is not a heading.
    def heading_level : Int32
      LibCmark.cmark_node_get_heading_level(@node_p)
    end

    # Sets the heading level of node; on failure it raises `NodeSetterError`.
    def heading_level=(heading_level : Int32) : Int32
      result = LibCmark.cmark_node_set_heading_level(@node_p, heading_level)
      setter_return_value
    end

    # Returns the list type of node, using `ListType::None` if node is not a list.
    def list_type : ListType
      ListType.new(LibCmark.cmark_node_get_list_type(@node_p).value)
    end

    # Sets the list type of node; on failure it raises `NodeSetterError`.
    def list_type=(list_type : ListType) : ListType
      result = LibCmark.cmark_node_set_list_type(@node_p, LibCmark::ListType.from_value(list_type.value))
      setter_return_value
    end

    # Returns the list delimiter of node, using `DelimType::None` if node is not a list.
    def list_delim : DelimType
      DelimType.new(LibCmark.cmark_node_get_list_delim(@node_p).value)
    end

    # Sets the list delimiter of node; on failure it raises `NodeSetterError`.
    def list_delim=(list_delim : DelimType) : DelimType
      result = LibCmark.cmark_node_set_list_delim(@node_p, LibCmark::DelimType.from_value(list_delim.value))
      setter_return_value
    end

    # Returns starting number of node, if it is an ordered list, otherwise 0.
    def list_start : Int
      LibCmark.cmark_node_get_list_start(@node_p)
    end

    # Sets the list delimiter of node; on failure it raises `NodeSetterError`.
    def list_start=(list_start : Int32) : Int32
      result = LibCmark.cmark_node_set_list_start(@node_p, list_start)
      setter_return_value
    end

    # Returns true if node is a tight list, or false if loose.
    def list_tight? : Bool
      LibCmark.cmark_node_get_list_tight(@node_p) > 0
    end

    # Sets the list tightness of node; on failure it raises `NodeSetterError`.
    def list_tight=(tight : Bool) : Bool
      result = LibCmark.cmark_node_set_list_tight(@node_p, tight)
      setter_return_value
    end

    # Returns the info string of a fenced code block.
    def fence_info : String
      String.new(LibCmark.cmark_node_get_fence_info(@node_p))
    end

    # Sets the info string of a fenced code block; on failure it raises `NodeSetterError`.
    def fence_info=(info : String) : String
      result = LibCmark.cmark_node_set_fence_info(@node_p, info)
      setter_return_value
    end

    # Returns fencing details of a code block.
    #
    # Returns nil if called on a node that is not a code block.
    def fencing_details : FencingDetails?
      fenced = LibCmark.cmark_node_get_fenced(@node_p, out length, out offset, out character_i) > 0
      return nil unless fenced && self.type.code_block?
      backtick = character_i.chr == '`'
      FencingDetails.new(length, offset, backtick)
    end

    # Sets fencing details of a code block; on failure it raises `NodeSetterError`.
    def fencing_details=(details : FencingDetails) : FencingDetails
      result = LibCmark.cmark_node_set_fenced(@node_p, 1, details.length, details.offset, details.character.ord)
      setter_return_value
    end

    # Returns the URL of a link or image node, or an empty string if no URL is set.
    def url : String
      result = LibCmark.cmark_node_get_url(@node_p)
      result.null? ? "" : String.new(result)
    end

    # Sets the URL of node; on failure it raises `NodeSetterError`.
    #
    # It must be called only on link or image nodes.
    def url=(url : String) : String
      result = LibCmark.cmark_node_set_url(@node_p, url)
      setter_return_value
    end

    # Returns the title of a link or image node, or an empty string if no title is set.
    def title : String
      result = LibCmark.cmark_node_get_title(@node_p)
      result.null? ? "" : String.new(result)
    end

    # Sets the title of a link or image node; on failure it raises `NodeSetterError`.
    def title=(title : String) : String
      result = LibCmark.cmark_node_set_title(@node_p, title)
      setter_return_value
    end

    # Returns the literal *on_enter* of a custom node or an empty string if unset.
    def on_enter : String
      result = LibCmark.cmark_node_get_on_enter(@node_p)
      result.null? ? "" : String.new(result)
    end

    # Sets the literal *on_enter* of a custom node; on failure it raises `NodeSetterError`.
    #
    # Any children of the node will be rendered after this text.
    def on_enter=(on_enter : String) : String
      result = LibCmark.cmark_node_set_on_enter(@node_p, on_enter)
      setter_return_value
    end

    # Returns the literal *on_exit* of a custom node or an empty string if unset.
    #
    # Returns nil if called on a node that is not custom.
    def on_exit : String
      result = LibCmark.cmark_node_get_on_exit(@node_p)
      result.null? ? "" : String.new(result)
    end

    # Sets the literal *on_exit* of a custom node; on failure it raises `NodeSetterError`.
    #
    # Any children of the node will be rendered before this text.
    def on_exit=(on_exit : String) : String
      result = LibCmark.cmark_node_set_on_exit(@node_p, on_exit)
      setter_return_value
    end

    # Returns the user data of node, which can then be unboxed.
    #
    # Example:
    # ```
    # node = NodeMaker.text("Hi")
    # node.user_data.null? # => true
    # node.user_data = Box.box(:greetings)
    # user_data = Box(Symbol).unbox(node.user_data)
    # user_data # => :grettings
    # ```
    def user_data : Pointer(Void)
      LibCmark.cmark_node_get_user_data(@node_p)
    end

    # Sets the user data of node, which should be already boxed; on failure it raises `NodeSetterError`.
    #
    # NOTE: *user_data* must be boxed into the node struct of the C library; see `#user_data`.
    def user_data=(user_data : Pointer(Void)) : Pointer(Void)
      result = LibCmark.cmark_node_set_user_data(@node_p, user_data)
      setter_return_value
    end

    # Returns the line on which node begins.
    def start_line : Int32
      LibCmark.cmark_node_get_start_line(@node_p)
    end

    # Returns the line on which node ends.
    def end_line : Int32
      LibCmark.cmark_node_get_end_line(@node_p)
    end

    # Returns the column on which node begins.
    def start_column : Int32
      LibCmark.cmark_node_get_start_column(@node_p)
    end

    # Returns the column on which node ends.
    def end_column : Int32
      LibCmark.cmark_node_get_end_column(@node_p)
    end

    # Returns true if the node is a Commonmark autolink, false otherwise.
    #
    # Beware that this method consolidates adjacent child text nodes if the node is a link.
    #
    # NOTE: When the GFM autolink extension is enabled, this method will not detect
    # [extended www autolink](https://github.github.com/gfm/#extended-www-autolink) nor
    # [extended autolink path validation](https://github.github.com/gfm/#extended-autolink-path-validation).
    # However, [extended email autolink](https://github.github.com/gfm/#extended-email-autolink)
    # together with simple autolinks constructed without the use of `<` and `>` as delimiters will
    # be recognized as autolinks.
    def autolink? : Bool
      # Adapted from the C library function "is_autolink"
      return false unless self.type.link?
      return false unless title == ""
      url = self.url
      return false if url.nil? || url.empty?
      link_text = self.first_child
      return false if link_text.nil?
      link_text.consolidate_text_nodes
      return false if link_text.literal.nil?
      real_url = url.starts_with?("mailto:") ? url[7..-1] : url
      link_text.literal == real_url
    end

    # == extensions

    # Returns the string content of tables and table cells, otherwise an empty string.
    #
    # With the following table
    #
    # ```text
    # | foo | bar |
    # | --- | --- |
    # | baz | bim |
    #```
    # the string content of table is the header row `| foo | bar |`. and the
    # string content of the cells is `foo`, `bar`, `baz`, and `bim`.
    #
    def table_string_content : String
      String.new(LibCmark.cmark_node_get_string_content(@node_p))
    end

    # Sets the table string content for tables and table cells.
    #
    # Beware of setting incorrect string content.
    # See `#table_string_content` for more information.
    def table_string_content=(content : String) : String
      result = LibCmark.cmark_node_set_string_content(@node_p, content)
      setter_return_value
    end

    # Returns the number of columns for the table.
    #
    # Returns 0 if called on a node that is not a table.
    def table_columns : UInt16
      LibCmark.cmark_gfm_extensions_get_table_columns(@node_p)
    end

    # Sets the number of columns for the table; on failure it raises `NodeSetterError`.
    #
    # It must be called only on table and table row nodes that already have defined columns.
    def table_columns=(n_columns : UInt16) : UInt16
      type = self.type
      if (type.table? || type.table_row?) && self.table_columns.zero?
        raise NodeSetterError.new("Cannot set table columns on a #{type} node with 0 columns")
      end
      result = LibCmark.cmark_gfm_extensions_set_table_columns(@node_p, n_columns)
      setter_return_value
    end

    # Returns the alignments of columns for the table.
    #
    # Returns an empty array if called on a node that is not a table.
    def table_alignments : Array(Alignment)
      alignments = [] of Alignment
      alignments_p = LibCmark.cmark_gfm_extensions_get_table_alignments(@node_p)
      n_columns = self.table_columns
      i = 0
      while i < n_columns
        alignments.push Alignment.from_value(alignments_p[i])
        i = i + 1
      end
      alignments
    end

    # Sets the alignments of columns for the table; on failure it raises `NodeSetterError`.
    #
    # It should be called only on table nodes.
    #
    # Example for a table node with two columns:
    # ```
    # node.table_alignments = [Alignment::Center, Alignment::Right]
    # ```
    def table_alignments=(alignments : Array(Alignment)) : Array(Alignment)
      alignments_p = Pointer.malloc(alignments.size) { |i| alignments[i].value }
      result = LibCmark.cmark_gfm_extensions_set_table_alignments(@node_p, alignments.size, alignments_p)
      setter_return_value
    end

    # Returns true if the the node is a header table row, false otherwise.
    def table_row_header? : Bool
      LibCmark.cmark_gfm_extensions_get_table_row_is_header(@node_p) > 0
    end

    # Sets a table row as table header.
    def table_row_header=(header : Bool) : Bool
      result = LibCmark.cmark_gfm_extensions_set_table_row_is_header(@node_p, header)
      setter_return_value
    end

    # Returns node table alignment or `Alignment::None` if called on a node that is not a table cell.
    def table_cell_alignment : Alignment
      return Alignment::None unless self.type.table_cell?
      parent_p = LibCmark.cmark_node_parent(@node_p)
      return Alignment::None if parent_p.null?
      grandparent_p = LibCmark.cmark_node_parent(parent_p)
      return Alignment::None if grandparent_p.null?
      loop_node_p = LibCmark.cmark_node_first_child(parent_p)
      i = 0
      while loop_node_p != @node_p
        loop_node_p = LibCmark.cmark_node_next(loop_node_p)
        i = i + 1 if LibCmark.cmark_node_get_type(loop_node_p) == LibCmark.cmark_node_table_cell
      end
      alignments_p = LibCmark.cmark_gfm_extensions_get_table_alignments(grandparent_p)
      Alignment.from_value(alignments_p[i])
    end

    # Returns true is a node is a tasklist item, false otherwise.
    def tasklist_item? : Bool
      if self.type.item?
        ext_p = LibCmark.cmark_node_get_syntax_extension(@node_p)
        ext_p.null? ? false : "tasklist" == String.new(ext_p.value.name)
      else
        false
      end
    end

    # Sets a list item as tasklist item; on failure it raises `NodeSetterError`.
    #
    # It must be called only on nodes with `NodeType::Item`.
    def tasklist_item=(tasklist : Bool) : Bool
      result = case
        when self.tasklist_item?
          tasklist ? 1 : LibCmark.cmark_node_set_syntax_extension(@node_p, nil)
        when self.type.item?
          if tasklist
            extension_p = LibCmark.cmark_find_syntax_extension("tasklist")
            LibCmark.cmark_node_set_syntax_extension(@node_p, extension_p)
          else
            1
          end
        else
          0
      end
      setter_return_value
    end

    # Returns true is a node is a tasklist_item and is checked, false otherwise.
    def tasklist_item_checked? : Bool
      LibCmark.cmark_gfm_extensions_get_tasklist_item_checked(@node_p) > 0
    end

    # Sets the checked status of tasklist item: on failure it raises `NodeSetterError`.
    def tasklist_item_checked=(checked : Bool) : Bool
      result = LibCmark.cmark_gfm_extensions_set_tasklist_item_checked(@node_p, checked)
      setter_return_value
    end

    # === Tree Manipulation

    # Unlinks this node from the AST.
    def unlink
      LibCmark.cmark_node_unlink(@node_p)
    end

    # Inserts sibling before node; raises `TreeManipulationError` on failure.
    def insert_before(sibling : Node)
      result = LibCmark.cmark_node_insert_before(@node_p, sibling.node_p)
      raise TreeManipulationError.new("Inserting #{sibling} before #{self} failed") if result.zero?
    end

    # Inserts sibling after node; raises `TreeManipulationError` on failure.
    def insert_after(sibling : Node)
      result = LibCmark.cmark_node_insert_after(@node_p, sibling.node_p)
      raise TreeManipulationError.new("Inserting #{sibling} after #{self} failed") if result.zero?
    end

    # Replaces node with *new_node*; raises `TreeManipulationError` on failure.
    def replace_with(new_node : Node)
      result = LibCmark.cmark_node_replace(@node_p, new_node.node_p)
      raise TreeManipulationError.new("Replacing #{self} with #{new_node} failed") if result.zero?
    end

    # Adds child to the beginning of the children of node; raises `TreeManipulationError` on failure.
    def prepend_child(child : Node)
      result = LibCmark.cmark_node_prepend_child(@node_p, child.node_p)
      raise TreeManipulationError.new("Prepending child #{child} for #{self} failed") if result.zero?
    end

    # Adds child to the end of the children of node; raises `TreeManipulationError` on failure.
    def append_child(child : Node)
      result = LibCmark.cmark_node_append_child(@node_p, child.node_p)
      raise TreeManipulationError.new("Appending child #{child} for #{self} failed") if result.zero?
    end

    # Consolidates adjacent text nodes.
    def consolidate_text_nodes
      LibCmark.cmark_consolidate_text_nodes(@node_p)
    end

    # === Rendering

    # Renders node tree an XML string.
    def render_xml(options = Option::None) : String
      result = LibCmark.cmark_render_xml(node_p, options)
      String.new(result)
    end

    # Renders node tree as an HTML string.
    def render_html(options = Option::None, extensions = Extension::None) : String
      # Only the tagfilter extension affects HTML rendering, but only if HTML handling is unsafe
      if options.unsafe? && extensions.tagfilter?
        mem_p = LibCmark.cmark_get_default_mem_allocator()
        list_p = LibCmark.cmark_list_syntax_extensions(mem_p)
        result = LibCmark.cmark_render_html(@node_p, options, list_p)
        LibCmark.cmark_llist_free(mem_p, list_p)
        String.new(result)
      else
        list_p = Pointer(LibCmark::CmarkLinkedList).null
        result = LibCmark.cmark_render_html(@node_p, options, list_p)
        String.new(result)
      end
    end

    # Renders node tree as a plaintext string.
    def render_plaintext(options = Option::None, width = 120) : String
      result = LibCmark.cmark_render_plaintext(node_p, options, width)
      String.new(result)
    end

    # Renders node tree as a commonmark string, including GFM extension nodes, if present.
    def render_commonmark(options = Option::None, width = 120) : String
      result = LibCmark.cmark_render_commonmark(node_p, options, width)
      String.new(result)
    end

    # Renders node tree as a LaTeX string.
    def render_latex(options = Option::None, width = 120) : String
      result = LibCmark.cmark_render_latex(node_p, options, width)
      String.new(result)
    end

    # Renders node tree as a groff man page string.
    def render_man(options = Option::None, width = 80) : String
      result = LibCmark.cmark_render_man(node_p, options, width)
      String.new(result)
    end

    # === Node containment

    # Returns true node can contain *node_type*, false otherwise.
    def can_contain?(node_type : NodeType) : Bool
      LibCmark.cmark_node_can_contain_type(@node_p, node_type) > 0
    end

    # === Other

    # Returns true if both instances point to the same underlying node structure.
    def ==(other : Node)
      @node_p == other.node_p
    end

    # :nodoc:
    def to_s(io)
      io << "<Cmark::Node:#{self.type}>"
    end

    # :nodoc:
    def inspect(io)
      io << "<Cmark::Node:0x#{self.object_id.to_s(16)}:#{self.type}>"
    end
  end
end
