require "../spec_helper"
include Cmark

describe NodeMaker do

  # Parameterless makers
  {% for name in [:document, :block_quote, :thematic_break, :softbreak, :linebreak, :emph, :strong, :item] %}
    describe ".{{name.id}}" do
      it "creates node of type {{name.id}}" do
        node = NodeMaker.{{name.id}}
        # See if we have created an invalid node by rendering it
        node.render_plaintext.should be_a String
        node.type.should eq NodeType::{{name.id.camelcase}}
      end
    end
  {% end %}

  # Makers with URL and title
  {% for name in [:link, :image] %}
    describe ".{{name.id}}" do
      it "creates a node of type {{name.id}} with title" do
        url = "http://example.com"
        title = "Go to example"
        node = NodeMaker.{{name.id}}(url, title)
        node.type.should eq NodeType::{{name.id.camelcase}}
        node.url.should eq url
        node.title.should eq title
      end

      it "creates a node of type {{name.id}} without title" do
        url = "http://example.com"
        node = NodeMaker.{{name.id}}(url)
        node.type.should eq NodeType::{{name.id.camelcase}}
        node.url.should eq url
        node.title.should eq ""
      end
    end
  {% end %}

  # Makers with literal
  {% for name in [:text, :code, :html_inline] %}
    describe ".{{name.id}}" do
      it "creates a node of type {{name.id}}" do
        literal = "Hello world"
        node = NodeMaker.{{name.id}}(literal)
        node.type.should eq NodeMaker.maybe_acronym_type({{name}})
        node.literal.should eq literal
      end
    end
  {% end %}

  describe ".paragraph" do
    it "creates a paragraph node and appends it to parent" do
      root = Cmark.parse_commonmark("Dummy text")
      node = NodeMaker.paragraph(root)
      node.type.should eq NodeType::Paragraph
      root.last_child.not_nil!.should eq node
    end
    it "creates a paragraph node and prepends it to parent" do
      root = Cmark.parse_commonmark("Dummy text")
      node = NodeMaker.paragraph(root, append: false)
      node.type.should eq NodeType::Paragraph
      root.first_child.not_nil!.should eq node
    end
  end

  describe ".heading" do
    it "creates a node with the given heading level" do
      node = NodeMaker.heading(2)
      node.type.should eq NodeType::Heading
      node.heading_level.should eq 2
    end
    it "creates a node with the default heading level" do
      node = NodeMaker.heading
      node.type.should eq NodeType::Heading
      node.heading_level.should eq 1
    end
  end

  describe ".list_as_bullet" do
    it "creates a node of type list and list_type bullet" do
      node = NodeMaker.list_as_bullet
      node.type.should eq NodeType::List
      node.list_tight?.should be_true
      node.list_type.should eq ListType::Bullet
    end
  end

  describe ".list_as_ordered" do
    it "creates node of type list and list_type ordered" do
      node = NodeMaker.list_as_ordered
      node.type.should eq NodeType::List
      node.list_tight?.should be_true
      node.list_type.should eq ListType::Ordered
      node.list_start.should eq 1
      node.list_delim.should eq DelimType::Period
    end
  end

  describe ".code_block" do
    it "creates node of type list and list_type ordered" do
      contents = <<-CR
        s = 1 + 1
        b = s - 1
      CR
      node = NodeMaker.code_block(contents ,"crystal")
      node.type.should eq NodeType::CodeBlock
      node.fence_info.should eq "crystal"
      node.literal.should eq contents
      node.fencing_details.should_not be_nil
    end
  end

  context "custom nodes" do
    on_enter = "<custom>"
    on_exit = "</custom>"
    {% for name in [:block, :inline] %}
      describe ".custom_{{name.id}}" do
        it "creates custom {{name.id}} node" do
          node = NodeMaker.custom_{{name.id}}(on_enter, on_exit)
          node.type.should eq NodeType::Custom{{name.id.camelcase}}
          node.on_enter.should eq on_enter
          node.on_exit.should eq on_exit
        end
      end
    {% end %}
  end

  context "extensions" do
    describe ".table" do
      contents = [] of Array(Node)
      contents.push [NodeMaker.text("foo"), NodeMaker.text("bar")]
      contents.push [NodeMaker.text("fiz"), NodeMaker.text("baz")]
      node = NodeMaker.table(contents)
      rows = EventIterator.new(node).modifiable_node_iterator.select &.type.table_row?
      cells = rows.select &.type.table_cell?

      it "creates a node of type table" do
        node.type.should eq NodeType::Table
      end
      it "creates a table node with the dimensions contents" do
        node.table_columns.should eq 2
        rows.size.should eq 2
      end
      it "sets table_string_content of table and table cells" do
        node.table_string_content.should_not be_empty
        rows.each { |row| row.table_string_content.should be_empty }
        cells.each { |cell| cell.table_string_content.should_not be_empty }
      end
    end

    describe ".table_row" do
      table_contents = [] of Array(Node)
      table_contents.push [NodeMaker.text("foo"), NodeMaker.text("bar")]
      table_contents.push [NodeMaker.text("fee"), NodeMaker.text("ber")]
      table = NodeMaker.table(table_contents)
      previous_table_row = table.first_child.not_nil!
      contents = [NodeMaker.text("fiz"), NodeMaker.text("baz"), ]
      table_row = NodeMaker.table_row(table, contents, previous_table_row)

      it "creates a node of type table row" do
        table_row.type.should eq NodeType::TableRow
      end
      it "creates a table row with the size of contents" do
        table_row.children.size.should eq 2
      end
      it "inserts table row as child of table after previous_row" do
        rows = table.children
        rows.size.should eq 3
        rows[1].should eq table_row
      end

      it "sets table_string_content of table and table cells" do
        table_row.children.each { |cell| cell.table_string_content.should_not be_empty }
      end
    end

    describe ".strikethrough" do
      it "creates a node of type strikethrough" do
        node = NodeMaker.strikethrough
        node.append_child NodeMaker.text("deleted")
        node.type.should eq(NodeType::Strikethrough)
        node.render_commonmark.should eq("~~deleted~~\n")
      end
    end

    describe ".tasklist" do
      it "creates an unchecked tasklist item" do
        node = NodeMaker.tasklist_item
        node.tasklist_item?.should be_true
        node.tasklist_item_checked?.should be_false
      end
      it "creates a checked tasklist item" do
        node = NodeMaker.tasklist_item(true)
        node.tasklist_item_checked?.should be_true
      end
    end
  end

end