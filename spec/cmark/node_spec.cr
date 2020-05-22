require "../spec_helper"
include Cmark

describe Node do
  describe "#initialize" do
    it "initializes with a string" do
      markdown = "Hello *world*"
      node = Cmark.parse_commonmark(markdown)
      node.should be_a Node
    end
  end

  describe "#type" do
    it "returns the node type" do
      markdown = "Hello ~~world~~"
      node = Cmark.parse_commonmark(markdown)
      node.type.should eq NodeType::Document
    end
  end

  describe "can_contain?" do
    it "returns the appropriate value for Commonmark nodes" do
      leaf = NodeMaker.text("Example")
      container = NodeMaker.strong
      leaf.can_contain?(container.type).should be_false
      container.can_contain?(leaf.type).should be_true
    end
    it "returns the appropriate value for GFM extension nodes" do
      contents = [] of Array(Node)
      contents.push [NodeMaker.text("Header")]
      table = NodeMaker.table(contents)
      table_row = table.first_child.not_nil!
      table_cell = table_row.first_child.not_nil!
      table_cell.can_contain?(table_row.type).should be_false
      table_row.can_contain?(table_cell.type).should be_true
    end
  end

  describe "#autolink?" do
    url = "http://example.com"
    email = "user@example.com"
    it "returns true for URLs parsed as autolinks" do
      root = Cmark.parse_commonmark("<#{url}>")
      node = root.first_child.not_nil!.first_child.not_nil!
      node.autolink?.should be_true
    end
    it "returns true for emails parsed as autolinks" do
      root = Cmark.parse_commonmark("<#{email}>")
      node = root.first_child.not_nil!.first_child.not_nil!
      node.autolink?.should be_true
    end
    it "returns true for links with same URL in child text node" do
      node = NodeMaker.link(url)
      node.append_child NodeMaker.text(url)
      node.autolink?.should be_true
    end
    it "returns false for links with different text in child text node" do
      node = NodeMaker.link(url)
      node.append_child NodeMaker.text("Example")
      node.autolink?.should be_false
    end
    it "returns true for email links with same email in child text node" do
      node = NodeMaker.link("mailto:#{email}")
      node.append_child NodeMaker.text(email)
      node.autolink?.should be_true
    end
    it "returns false for links with title and same URL in child text node" do
      node = NodeMaker.link(url, "Example")
      node.append_child NodeMaker.text(url)
      node.autolink?.should be_false
    end
    it "returns false for links without text node" do
      node = NodeMaker.link(url)
      node.autolink?.should be_false
    end
  end

  context "literal" do
    markdown = "Hello"
    text_node = Cmark.parse_commonmark(markdown).first_child.not_nil!.first_child.not_nil!

    describe "#literal" do
      it "returns the node literal" do
        text_node.literal.should eq "Hello"
      end
    end
    describe "#literal=" do
      it "sets the node literal" do
        text_node.literal = "world"
        text_node.literal.should eq "world"
      end
    end
  end

  context "heading_level" do
    markdown = "## Heading"
    heading_node = Cmark.parse_commonmark(markdown).first_child.not_nil!

    describe "#heading_level" do
      it "returns the node heading level" do
        heading_node.heading_level.should eq 2
      end
    end
    describe "#heading_level=" do
      it "sets the node heading level" do
        heading_node.heading_level = 3
        heading_node.heading_level.should eq 3
      end
    end
  end

  context "list_type" do
    markdown = "* Listing"
    list_node = Cmark.parse_commonmark(markdown).first_child.not_nil!

    describe "#list_type" do
      it "returns the node list type" do
        list_node.list_type.should eq ListType::Bullet
      end
    end
    describe "#list_type=" do
      it "sets the node list type" do
        result = list_node.list_type = ListType::Ordered
        result.should eq list_node.list_type
        result.should eq ListType::Ordered
      end
    end
  end

  context "list_delim" do
    markdown = "1. Listing"
    list_node = Cmark.parse_commonmark(markdown).first_child.not_nil!

    describe "#list_delim" do
      it "returns the node list delimiter" do
        list_node.list_delim.should eq DelimType::Period
      end
    end
    describe "#list_delim=" do
      it "sets the node list delimiter" do
        list_node.list_delim = DelimType::Paren
        list_node.list_delim.should eq DelimType::Paren
      end
    end
  end

  context "list_start" do
    markdown = " 5) Listing"
    list_node = Cmark.parse_commonmark(markdown).first_child.not_nil!

    describe "#list_start" do
      it "returns the node list start" do
        list_node.list_start.should eq(5)
      end
    end
    describe "#list_start=" do
      it "sets the node list start" do
        list_node.list_start = 4
        list_node.list_start.should eq(4)
      end
    end
  end

  context "list_tight" do
    markdown = " 1. Listing A \n\n 2. Listing B"
    list_node = Cmark.parse_commonmark(markdown).first_child.not_nil!

    describe "#list_tight?" do
      it "returns the node list tightness" do
        list_node.list_tight?.should be_false
      end
    end
    describe "#list_tight?" do
      it "sets the node list tightness" do
        list_node.list_tight = true
        list_node.list_tight?.should be_true
      end
    end
  end

  context "fence_info" do
    markdown = "```crystal\n  1 + 2\n```"

    describe "#fence_info" do
      it "returns the information of a fenced code node" do
        node = Cmark.parse_commonmark(markdown)
        fence_node = node.first_child.not_nil!
        fence_node.fence_info.should eq "crystal"
      end
    end
    describe "#fence_info=" do
      it "returns the information of a fenced code node" do
        node = Cmark.parse_commonmark(markdown)
        fence_node = node.first_child.not_nil!
        result = fence_node.fence_info = "ruby"
        result.should eq "ruby"
        fence_node.fence_info.should eq "ruby"
      end
    end
  end

  context "fencing_details" do
    markdown = "```crystal\n  1 + 2\n```"

    describe "#fencing_details" do
      it "returns the node fencing details of a fenced code block" do
        node = Cmark.parse_commonmark(markdown)
        fence_node = node.first_child.not_nil!
        details = fence_node.fencing_details.not_nil!
        details.length.should eq 3
        details.offset.should eq 0
        details.backtick?.should be_true
      end
      it "returns the node fencing details of a non-fenced node as nil" do
        node = Cmark.parse_commonmark("Hello")
        node = node.first_child.not_nil!
        node.fencing_details.should be_nil
      end
    end

    describe "#fencing_details=" do
      it "returns the node fencing details of a fenced code block" do
        node = Cmark.parse_commonmark(markdown)
        fence_node = node.first_child.not_nil!
        new_details = FencingDetails.new(2, 1, false)
        fence_node.fencing_details = new_details
        node_details = fence_node.fencing_details.not_nil!
        node_details.length.should eq 2
        node_details.offset.should eq 1
        node_details.tilde?.should be_true
      end
    end
  end

  context "link and image nodes" do
    url = "http://example.com"
    new_url = "http://anotherexample.com"
    title = "URL Title"
    new_title = "New URL Title"
    markdown = <<-MD
      [link](#{url} "#{title}")
      ![image](#{url} "#{title}")
    MD
    root = Cmark.parse_commonmark(markdown)
    paragraph = root.first_child.not_nil!
    link_node = paragraph.first_child.not_nil!
    image_node = paragraph.last_child.not_nil!

    describe "#url" do
      it "returns the URL of a link node" do
        link_node.url.should eq url
      end
      it "returns the URL of an image node" do
        image_node.url.should eq url
      end
      it "returns an empty string for nodes that are not link or image" do
        non_link_node = NodeMaker.text(title)
        non_link_node.url.should be_empty
      end
    end
    describe "#url=" do
      it "sets the URL of a link node" do
        result = link_node.url = new_url
        result.should eq new_url
        link_node.url.should eq new_url
      end
      it "sets the URL of an image node" do
        result = link_node.url = new_url
        result.should eq new_url
        link_node.url.should eq new_url
      end
    end

    describe "#title" do
      it "returns the title of a link node" do
        link_node.title.should eq title
      end
      it "returns the title of an image node" do
        image_node.title.should eq title
      end
      it "returns an empty string for nodes that are not link or image" do
        non_link_node = NodeMaker.text(title)
        non_link_node.title.should be_empty
      end
    end
    describe "#title=" do
      it "sets the title of a link node" do
        result = link_node.title = new_title
        result.should eq new_title
        link_node.title.should eq new_title
      end
      it "sets the title of an image node" do
        result = link_node.title = new_title
        result.should eq new_title
        link_node.title.should eq new_title
      end
    end
  end


  describe "user_data accessors" do
    it "sets and gets user data on node" do
      data = :greetings
      node = NodeMaker.text("Hi")
      node.user_data.null?.should be_true
      node.user_data = Box.box(data)
      user_data = Box(Symbol).unbox(node.user_data)
      user_data.should eq data
    end

    it "sets and gets user data on node" do
      data = :greetings
      node = NodeMaker.text("Hi")
      node.user_data = Box(Symbol).box(data)
      user_data = Box(Symbol).unbox(node.user_data)
      user_data.should eq data
    end
  end

  context "traversing" do
    root = Cmark.parse_commonmark("Hello *world*!")
    paragraph = root.first_child.not_nil!
    first_text = paragraph.first_child.not_nil!


    # <document xmlns="http://commonmark.org/xml/1.0">
    #   <paragraph>
    #     <text xml:space="preserve">Hello </text>
    #     <emph>
    #       <text xml:space="preserve">world</text>
    #     </emph>
    #     <text xml:space="preserve">!</text>
    #   </paragraph>
    # </document>

    describe "#parent" do
      it "returns the parent if available" do
        parent = paragraph.parent
        parent.should eq root
      end
    end
    describe "#grandparent" do
      it "returns the parent if available" do
        grandparent = first_text.grandparent
        grandparent.should eq root
      end
    end
    describe "#first_child" do
      it "returns the first child if available" do
        first_child = root.first_child
        first_child.should eq paragraph
      end
    end
    describe "#last_child" do
      it "returns the last child if available" do
        last_child = paragraph.last_child.not_nil!
        last_child.type.should eq(NodeType::Text)
        literal = last_child.literal
        literal.should eq "!"
      end
    end
    describe "#next" do
      it "returns the next node if available" do
        next_node = first_text.next.not_nil!
        next_node.type.should eq(NodeType::Emph)
      end
    end
    describe "#previous" do
      it "returns the previous node if available" do
        last_child = paragraph.last_child.not_nil!
        previous_node = last_child.previous.not_nil!
        previous_node.type.should eq(NodeType::Emph)
      end
    end
    describe "#children" do
      it "returns all available children" do
        children = paragraph.children
        children.size.should eq 3
        children[0].type.text?.should be_true
        children[1].type.emph?.should be_true
        children[2].type.text?.should be_true
      end
      it "returns an empty array if there are no children" do
        first_text.children.should be_empty
      end
    end
  end

  context "rendering" do
    root = Cmark.parse_commonmark("Hello *world*")

    describe "#render_xml" do
      it "renders as an XML string" do
        rendering = root.render_xml
        rendering.should contain("<emph>")
      end
    end
    describe "#render_html" do
      it "renders as an HTML string" do
        rendering = root.render_html
        rendering.should eq "<p>Hello <em>world</em></p>\n"
      end
      context "options and extensions" do
        markdown = "<title>Hi</title>\n\nContent"
        raw_root = Cmark.parse_document(markdown, extensions: Extension::Table)

        it "renders as an HTML string without extensions"  do
          rendering = raw_root.render_html(Option::Unsafe)
          rendering.should eq "<title>Hi</title>\n<p>Content</p>\n"
        end
        it "renders as an HTML string with extensions" do
          rendering = raw_root.render_html(Option::Unsafe, Extension::All)
          rendering.should eq "&lt;title>Hi&lt;/title>\n<p>Content</p>\n"
        end
      end
    end
    describe "#render_man" do
      it "renders as a groph man string" do
        rendering = root.render_man
        rendering.should eq ".PP\nHello \\f[I]world\\f[]\n"
      end
    end
    describe "#render_commonmark" do
      it "renders as a commonmark string" do
        rendering = root.render_commonmark
        rendering.should eq "Hello *world*\n"
      end
    end
    describe "#render_plaintext" do
      it "renders as a plaintext string" do
        rendering = root.render_plaintext
        rendering.should eq "Hello world\n"
      end
    end
    describe "#render_latex" do
      it "renders as a LaTeX string" do
        rendering = root.render_latex
        rendering.should eq "Hello \\emph{world}\n"
      end
    end
  end

  context "extensions" do
    context "tables" do
      markdown = <<-MD
      | foo | bar | fii | bor |
      | --- |:--- |:---:| ---:|
      | baz | bim | biz | bum |
      MD

      context "table_columns" do
        root = Cmark.parse_document(markdown, extensions: Cmark::Extension::Table);
        table = root.first_child.not_nil!

        describe "#table_columns" do
          it "returns the number of columns" do
            table_row = table.first_child.not_nil!
            table_cell = table_row.first_child.not_nil!
            table.table_columns.should eq(4)
          end
        end
        describe "#table_columns=" do
          it "sets the number of columns" do
            table.table_columns = 1
            table.table_columns.should eq(1)
          end
        end
      end

      context "table_alignments" do
        root = Cmark.parse_document(markdown, extensions: Cmark::Extension::Table)
        table = root.first_child.not_nil!

        describe "#table_alignments" do
          it "returns the alignments" do
            expected = [Alignment::None, Alignment::Left, Alignment::Center, Alignment::Right]
            table.table_alignments.should eq(expected)
          end
        end
        describe "#table_alignments=" do
          it "sets the number of alignments" do
            alignments = Array.new(4, Alignment::Center)
            table.table_alignments = alignments
            table.table_alignments.should eq(alignments)
          end
        end
      end

      context "table_row_header" do
        root = Cmark.parse_document(markdown, extensions: Cmark::Extension::Table)
        table = root.first_child.not_nil!
        first_row = table.first_child.not_nil!
        second_row = table.last_child.not_nil!

        describe "#table_row_header?" do
          it "returns true for header rows" do
            first_row.table_row_header?.should be_true
          end
          it "returns false for non-header rows" do
            second_row.table_row_header?.should be_false
          end
        end
        describe "#table_row_header=" do
          it "sets if a table row is a header or not " do
            # Swap first and second rows
            first_row.unlink
            second_row.unlink
            first_row.table_row_header = false
            second_row.table_row_header = true
            table.append_child(second_row)
            table.append_child(first_row)
            second_row.table_row_header?.should be_true
            first_row.table_row_header?.should be_false
          end
        end

        context "table_string_content" do
          root = Cmark.parse_document(markdown, extensions: Cmark::Extension::Table)
          table = root.first_child.not_nil!
          header_row = table.first_child.not_nil!
          normal_row = table.last_child.not_nil!
          header_cell = header_row.first_child.not_nil!
          normal_cell = normal_row.first_child.not_nil!

          describe "#table_string_content" do
            it "returns the string content of a table node" do
              table.table_string_content.should_not be_empty
            end
            it "returns the string content of table cell nodes" do
              header_cell.table_string_content.should_not be_empty
              normal_cell.table_string_content.should_not be_empty
            end
          end
        end

        describe "table_cell_alignment" do
          root = Cmark.parse_document(markdown, extensions: Cmark::Extension::Table)
          table = root.first_child.not_nil!
          normal_row = table.last_child.not_nil!
          last_normal_cell = normal_row.last_child.not_nil!

          it "returns none if called on a node that is not a table cell" do
            normal_row.table_cell_alignment.should eq Alignment::None
          end

          it "returns the table cell alignment" do
            last_normal_cell.table_cell_alignment.should eq Alignment::Right
          end
        end

      end
    end

    context "tasklist" do
      markdown = <<-MD
        - [x] done
        - [ ] to do
        - No task
      MD
      context "tasklist_item" do
        root = Cmark.parse_document(markdown, extensions: Extension::Tasklist)
        list = root.first_child.not_nil!
        first_item  = list.first_child.not_nil!
        second_item = first_item.next.not_nil!
        third_item  = list.last_child.not_nil!

        describe "tasklist_item?" do
          it "returns true for checked tasklist item" do
            first_item.tasklist_item?.should be_true
          end
          it "returns true for unchecked tasklist item" do
            second_item.tasklist_item?.should be_true
          end
          it "returns false for non-tasklist item" do
            third_item.tasklist_item?.should be_false
          end
          it "returns false for non-list item" do
            NodeMaker.text("test").tasklist_item?.should be_false
          end
        end
        describe "tasklist_item=" do
          it "has not effect on tasklist item if set to true" do
            result = first_item.tasklist_item = true
            result.should be_true
            first_item.tasklist_item?.should be_true
          end
          it "changes a tasklist item into list item if set to false" do
            result = second_item.tasklist_item = false
            second_item.tasklist_item?.should be_false
            second_item.type.item?.should be_true
          end
          it "has not effect on list items if set to false" do
            result = third_item.tasklist_item = false
            result.should be_false
            third_item.tasklist_item?.should be_false
          end
          it "changes a list item into tasklist item if set to true",  do
            result = third_item.tasklist_item = true
            result.should be_true
            third_item.tasklist_item?.should be_true
          end
          it "raises NodeSetterError for non-list items" do
            expect_raises(NodeSetterError) do
              NodeMaker.text("test").tasklist_item = true
            end
          end
        end
      end

      context "tasklist_item_checked" do
        root = Cmark.parse_document(markdown, extensions: Extension::Tasklist)
        list = root.first_child.not_nil!
        first_item  = list.first_child.not_nil!
        second_item = first_item.next.not_nil!
        third_item  = list.last_child.not_nil!

        describe "tasklist_item_checked?" do
          it "returns true for checked tasklist item" do
            first_item.tasklist_item_checked?.should be_true
          end
          it "returns false for non-checked tasklist item" do
            second_item.tasklist_item_checked?.should be_false
          end
          it "returns false for non-tasklist item" do
            third_item.tasklist_item_checked?.should be_false
          end
          it "returns false for non-list item" do
            NodeMaker.text("test").tasklist_item_checked?.should be_false
          end
        end
        describe "tasklist_item_checked=" do
          it "has not effect on checked tasklist item if set to true" do
            result = first_item.tasklist_item_checked = true
            result.should be_true
            first_item.tasklist_item_checked?.should be_true
          end
          it "unchecks a checked tasklist item if set to false" do
            result = first_item.tasklist_item_checked = false
            result.should be_false
            first_item.tasklist_item_checked?.should be_false
          end
          it "has not effect on unchecked tasklist item if set to false" do
            result = second_item.tasklist_item_checked = false
            result.should be_false
            second_item.tasklist_item_checked?.should be_false
          end
          it "checks an unchecked tasklist item if set to true" do
            result = first_item.tasklist_item_checked = true
            result.should be_true
            first_item.tasklist_item_checked?.should be_true
          end
          it "raises NodeSetterError for non-tasklist items" do
            expect_raises(NodeSetterError) do
              third_item.tasklist_item_checked = false
            end
          end
          it "raises NodeSetterError for non-list items" do
            expect_raises(NodeSetterError) do
              NodeMaker.text("test").tasklist_item_checked = true
            end
          end
        end
      end
    end
  end
end
