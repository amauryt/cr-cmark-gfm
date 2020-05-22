require "./lib_cmark"

module Cmark
  # A convenience class to safely create `Node` instances with a predefined `NodeType`.
  #
  # NOTE: The methods herein only create the given node(s) *per se*,
  # **it is the responsibility of the module user to create and assign the necessary
  # parent and child nodes of the respective created nodes**.
  module NodeMaker

    # :nodoc:
    macro maybe_acronym_type(name)
      {% if name.id.starts_with?("html") %}
        {% components = name.id.split('_') %}
        {% type_name = components[0].upcase + components[1].camelcase %}
      {% else %}
        {% type_name = name.id.camelcase %}
      {% end %}
      NodeType::{{type_name.id}}
    end

    # Parameterless makers
    {% for name in [:document, :block_quote, :thematic_break, :softbreak, :linebreak, :emph, :strong, :item] %}
      # Makes a node with `NodeType::{{name.id.camelcase}}`.
      def self.{{name.id}} : Node
        Node.new(LibCmark::NodeType::CMARK_NODE_{{name.id.upcase}})
      end
    {% end %}

    # Makers with URL and title
    {% for name in [:link, :image] %}
      # Makes a node with `NodeType::{{name.id.camelcase}}`.
      def self.{{name.id}}(url : String, title = "") : Node
        node = Node.new(LibCmark::NodeType::CMARK_NODE_{{name.id.upcase}})
        node.url = url
        node.title = title
        node
      end
    {% end %}

    # Markers with literal
    {% for name in [:text, :code, :html_inline, :html_block] %}
      {% if name.id.starts_with?("html") %}
        {% components = name.id.split('_') %}
        {% type_name = components[0].upcase + components[1].camelcase %}
      {% else %}
        {% type_name = name.id.camelcase %}
      {% end %}
      # Makes a node with `NodeType::{{type_name.id}}`.
      def self.{{name.id}}(literal : String) : Node
        node = Node.new(LibCmark::NodeType::CMARK_NODE_{{name.id.upcase}})
        node.literal = literal
        node
      end
    {% end %}

    # Makes a node with `NodeType::Paragraph` as child of the given _parent_.
    #
    # If _append_ is true the new paragraph will be appended as child of _parent_,
    # otherwise it will be prepended as child.
    #
    # It raises `Cmark::TreeManipulationError` if cannot be inserted as child of _parent_.
    #
    # NOTE: a paragraph node could theoretically be created without a parent.
    # However, the HTML renderer of the underlying C library assumes that
    # a paragraph node will always have a parent.
    # Given that most users will render use such HTML rendering anyways,
    # it is better to be safe than to have an invalid memory access.
    def self.paragraph(parent : Node, append = true) : Node
      node = Node.new(LibCmark::NodeType::CMARK_NODE_PARAGRAPH)
      if append
        parent.append_child(node)
      else
        parent.prepend_child(node)
      end
      node
    end

    def self.heading(level : Int32 = 1) : Node
      node = Node.new(LibCmark::NodeType::CMARK_NODE_HEADING)
      node.heading_level = level
      node
    end

    # Makes a node with `NodeType::List` with `ListType::Bullet`.
    def self.list_as_bullet(tight : Bool = true)
      node = Node.new(LibCmark::NodeType::CMARK_NODE_LIST)
      node.list_tight = tight
      node.list_type = ListType::Bullet
      node
    end

    # Makes a node with `NodeType::List` with `ListType::Ordered`.
    def self.list_as_ordered(tight : Bool = true, start = 1, delim = DelimType::Period)
      node = Node.new(LibCmark::NodeType::CMARK_NODE_LIST)
      node.list_tight = tight
      node.list_type = ListType::Ordered
      node.list_start = start
      node.list_delim = delim
      node
    end

    def self.code_block(contents : String, fence_info : String = "")
      node = Node.new(LibCmark::NodeType::CMARK_NODE_CODE_BLOCK)
      node.fence_info = fence_info
      node.fencing_details = FencingDetails.new(3, 0, true)
      node.literal = contents
      node
    end

    # Custom nodes
    {% for name in [:block, :inline] %}
      # Mades a node with `NodeType::CUSTOM_{{name.id.upcase}}`.
      def self.custom_{{name.id}}(on_enter : String =  "", on_exit : String = "")
        node = Node.new(LibCmark::NodeType::CMARK_NODE_CUSTOM_{{name.id.upcase}})
        node.on_enter = on_enter
        node.on_exit = on_exit
        node
      end
    {% end %}




    # Makes a node with `NodeType::Table` using a bidimensional array of `Node` for _contents_,
    # with the first array of nodes being its headers.
    #
    # Non-header arrays of nodes can be of different size with respect to the the header array of nodes.
    # If the non-header array's size is greater than the header's size, the nodes in excess will be discarded.
    # If, on the contrary, the non-header array's size is less than the header's size, the table row will be padded with empty cells.
    #
    # It raises `Cmark::Error` if the headers or _contents_ arrays are empty.
    #
    # It raises `Cmark::TreeManipulationError` if any node in _contents_ cannot be appended
    # to its respective table cell.
    #
    #
    # This example
    # ```
    # include NodeMaker
    # contents = [] of Array(Node)
    # contents.push [text("foo"), text("bar")]
    # contents.push [text("fiz"), text("baz")]
    # node = table(contents)
    # node.render_html
    # ```
    # renders the following HTML (formatted for better reading):
    # ```text
    # <table>
    #   <thead>
    #     <tr>
    #       <th>foo</th>
    #       <th>bar</th>
    #     </tr>
    #   </thead>
    #   <tbody>
    #     <tr>
    #       <td>fiz</td>
    #        <td>baz</td>
    #     </tr>
    #   </tbody>
    # </table>
    # ```
    def self.table(contents : Array(Array(Node))) : Node
      raise Cmark::Error.new("Table contents cannot be empty") if contents.empty?
      headers = contents.first
      raise Cmark::Error.new("Table headers cannot be empty") if headers.empty?
      # Create a dummy markdown table witn the dimensions of contents, as at
      # the moment directly creating Table extension nodes is problematic.
      # See https://github.com/github/cmark-gfm/issues/159
      str = String.build do |str|
        str << "|"
        headers.size.times { str << " |"}
        str << "\n|"
        headers.size.times { str << "-|"}
        (contents.size - 1).times do
          str << "\n|"
          headers.size.times { str << " |"}
        end
      end
      root = Cmark.parse_document(str, extensions: Extension::Table)
      table = root.first_child.not_nil!
      table.unlink
      row = col = 0
      EventIterator.new(table).modifiable_node_iterator.each do |table_element|
        if table_element.type.table_cell?
          if node = contents[row][col]?
            table_element.append_child(node)
            table_element.table_string_content = node.render_commonmark
          end
          col = col + 1
        elsif table_element.type.table_row?
          row = row + 1
          col = 0
        end
      end
      header_cells = table.first_child.not_nil!.children
      table.table_string_content = "| #{(header_cells.map &.table_string_content).join(" | ")} |"
      table
    end

    # Makes a node with `NodeType::Table` using _contents_ to populate its cells; if *previous_table_row*
    # is not nil then the new row is inserted after it, otherwise it is appended as a child of _table_.
    #
    # NOTE: If creating a table from scratch is better to use `.table`.
    #
    # If _contents_ size is greater than the number of columns in _table_, the nodes in excess will be discarded.
    # If, on the contrary, _contents_ size is less than number of columns, the table row will be padded with empty cells.
    #
    # It raises `Cmark::Error` if  _contents_ is empty, if _table_ is not a node with `NodeType::Table`,
    # or if *previous_table_row* is set but is not a child of _table_.
    #
    # It raises `Cmark::TreeManipulationError` if any node in _contents_ cannot be appended
    # to its respective table cell.
    #
    # This example
    # ```
    # include NodeMaker
    # table_contents = [] of Array(Node)
    # table_contents.push [text("foo"), text("bar")]
    # table_contents.push [text("fee"), text("ber")]
    # table_node = table(table_contents)
    # previous_table_row = table_node.first_child.not_nil!
    # contents = [text("fiz"), text("baz")]
    # table_row_node = table_row(table, contents, previous_table_row)
    # table_node.render_html
    # ```
    # renders the following HTML (formatted for better reading):
    # ```text
    # <table>
    #   <thead>
    #     <tr>
    #       <th>foo</th>
    #       <th>bar</th>
    #     </tr>
    #   </thead>
    #   <tbody>
    #     <tr>
    #       <td>fiz</td>
    #        <td>baz</td>
    #     </tr>
    #     <tr>
    #       <td>fee</td>
    #        <td>ber</td>
    #     </tr>
    #   </tbody>
    # </table>
    # ```
    def self.table_row(table : Node, contents : Array(Node), previous_table_row : Node? = nil) : Node
      raise Cmark::Error.new("Table row contents cannot be empty") if contents.empty?
      raise Cmark::Error.new("#{table} is not a table") unless table.type.table?
      raise Cmark::Error.new("#{previous_table_row} is not a child of #{table}") if !previous_table_row.nil? && !previous_table_row.parent == table
      n_columns = table.table_columns
      # Create a dummy table. See the inner comments of `.table`.
      str = String.build do |str|
        str << "|"
        n_columns.times { str << " |"}
        str << "\n|"
        n_columns.times { str << "-|"}
      end
      root = Cmark.parse_document(str, extensions: Extension::Table)
      dummy_table = root.first_child.not_nil!
      table_row = dummy_table.first_child.not_nil!
      table_row.table_row_header = false
      EventIterator.new(table_row).modifiable_node_iterator.each_with_index do |table_cell, index|
        if node = contents[index]?
          table_cell.append_child(node)
          table_cell.table_string_content = node.render_commonmark
        end
      end
      table_row.unlink
      if previous_table_row.nil?
        table.append_child(table_row)
      else
        after_insertion_rows = [] of Node
        found = false
        row_iterator = EventIterator.new(table).modifiable_node_iterator.select &.type.table_row?
        row_iterator.each do |row|
          if found
            row.unlink
            after_insertion_rows.push(row)
          end
          found = true if row == previous_table_row
        end
        table.append_child(table_row)
        after_insertion_rows.each {|row| table.append_child row }
      end
      dummy_table.unlink
      table_row
    end

    # Makes a node with `NodeType::Strikethrough`.
    def self.strikethrough : Node
      node = Node.new(LibCmark.cmark_node_strikethrough)
      extension_p = LibCmark.cmark_find_syntax_extension("strikethrough")
      LibCmark.cmark_node_set_syntax_extension(node.node_p, extension_p)
      node
    end

    # Makes a tasklist extension node with `NodeType::Item`, which is _checked_ or not.
    #
    # To check if a given node is a tasklist item use `Node#tasklist_item?`.
    def self.tasklist_item(checked : Bool = false)
      node = NodeMaker.item
      extension_p = LibCmark.cmark_find_syntax_extension("tasklist")
      LibCmark.cmark_node_set_syntax_extension(node.node_p, extension_p)
      node.tasklist_item_checked = checked
      node
    end
  end
end