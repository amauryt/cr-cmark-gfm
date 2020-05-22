require "../../spec_helper"
include Cmark

describe "HTMLRenderer" do

  describe "#document" do
    it "renders" do
      node = NodeMaker.document
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "#block_quote" do
    it "renders" do
      node = NodeMaker.block_quote
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      node = NodeMaker.block_quote
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
  end

  describe "#list" do
    context "bullet list" do
      node = NodeMaker.list_as_bullet

      it "renders" do
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
      it "renders with sourcepos" do
        options = Option::Sourcepos
        renderer = HTMLRenderer.new(options)
        renderer.render(node).should eq node.render_html(options)
      end
    end
    context "ordered list" do
      node = NodeMaker.list_as_ordered
      options = Option::Sourcepos

      it "renders" do
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
      it "renders with sourcepos" do
        renderer = HTMLRenderer.new(options)
        renderer.render(node).should eq node.render_html(options)
      end
      it "renders with a custom list start" do
        node.list_start = 5
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
    end
  end

  describe "#item" do
    it "renders" do
      node = NodeMaker.item
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      node = NodeMaker.item
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders as unchecked tasklist" do
      node = NodeMaker.tasklist_item(false)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders as checked tasklist" do
      node = NodeMaker.tasklist_item(true)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "#code_block" do
    contents = "r = 1 + 1\n b = 2 + 2"
    it "renders without fence info" do
      node = NodeMaker.code_block(contents)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      node = NodeMaker.code_block(contents)
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with lang fence info" do
      node = NodeMaker.code_block(contents, "crystal")
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with lang and metadata fence info with option full_info_string" do
      options = Option::FullInfoString
      node = NodeMaker.code_block(contents, "crystal test")
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with lang fence info with options github_pre_lang " do
      options = Option::GithubPreLang
      node = NodeMaker.code_block(contents, "crystal")
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with lang and metadata fence info with options github_pre_lang and full_info_string)" do
      options = Option::GithubPreLang | Option::FullInfoString
      node = NodeMaker.code_block(contents, "crystal test")
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
  end

  describe "#html_block" do
    contents = <<-HTML
      <title>text</title>
      <span>text</span>
      HTML
    it "renders without options nor extensions" do
      node = NodeMaker.html_block(contents)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with unsafe option" do
      options = Option::Unsafe
      node = NodeMaker.html_block(contents)
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with unsafe option and tagfilter extension" do
      params = { options: Option::Unsafe, extensions: Extension::Tagfilter }
      node = NodeMaker.html_block(contents)
      renderer = HTMLRenderer.new(**params)
      # In cmark-gfm, the closing tags of filtered content in HTML Blocks
      # are also escaped, for simplicity in the renderer only the opening
      # tags are escaped.
      # node.render_html      # => "&lt;title>text&lt;/title>\n<span>text</span>\n"
      # renderer.render(node) # => "&lt;title>text</title>\n<span>text</span>\n"
      renderer.render(node).match(/&lt;/).should_not be_nil
    end
  end

  describe "#custom_block" do
    it "renders" do
      node = NodeMaker.custom_block("<sup>", "</sup>")
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "#paragraph" do
    it "renders" do
      node = NodeMaker.paragraph(parent: NodeMaker.document)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      node = NodeMaker.paragraph(parent: NodeMaker.document)
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "does not render if grandchild of a tight list" do
      grandparent = NodeMaker.list_as_bullet
      parent = NodeMaker.item
      grandparent.list_tight = true
      grandparent.append_child parent
      node = NodeMaker.paragraph(parent)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
      renderer.render(node).should be_empty
    end
  end

  describe "#heading" do
    it "renders" do
      node = NodeMaker.heading(1)
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      node = NodeMaker.heading(1)
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
  end

  describe "#thematic_break" do
    it "renders" do
      node = NodeMaker.thematic_break
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      node = NodeMaker.thematic_break
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
  end

  describe "#text" do
    it "renders" do
      node = NodeMaker.text("This is a test")
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "#softbreak" do
    node = NodeMaker.softbreak
    it "renders without options" do
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with hardbreaks option" do
      options = Option::Hardbreaks
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with nobreaks option" do
      options = Option::Nobreaks
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
  end

  describe "linebreak" do
    it "renders" do
      node = NodeMaker.linebreak
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "code" do
    it "renders" do
      node = NodeMaker.code("name")
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "html_inline" do
    it "renders without options nor extensions" do
      node = NodeMaker.html_inline("<title>text</title>")
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with unsafe option" do
      options = Option::Unsafe
      node = NodeMaker.html_inline("<title>text</title>")
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with tagfilter extension" do
      extensions = Extension::Tagfilter
      node = NodeMaker.html_inline("<title>text</title>")
      renderer = HTMLRenderer.new(extensions: extensions)
      renderer.render(node).should eq node.render_html(extensions: extensions)
    end
    it "renders with unsafe option and tagfilter extension" do
      params = { options: Option::Unsafe, extensions: Extension::Tagfilter }
      node = NodeMaker.html_inline("<title>text</title>")
      renderer = HTMLRenderer.new(**params)
      renderer.render(node).should eq node.render_html(**params)
    end
  end

  describe "#custom_inline" do
    it "renders" do
      node = NodeMaker.custom_inline("<sup>", "</sup>")
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "#emph" do
    it "renders" do
      node = NodeMaker.emph
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  describe "#strong" do
    it "renders" do
      node = NodeMaker.strong
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end

  context "link and image nodes" do
    url = "http://example.com"
    title = "Go to example"
    text_contents = "Example"

    describe "#link" do
      it "renders with only url and text" do
        node = NodeMaker.link(url)
        node.append_child NodeMaker.text(text_contents)
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
      it "renders with url, text and title" do
        node = NodeMaker.link(url, title)
        node.append_child NodeMaker.text(text_contents)
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
    end
    describe "#image" do
      it "renders with only url" do
        node = NodeMaker.image(url)
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
      it "renders with only url and title" do
        node = NodeMaker.image(url, title)
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
      it "renders with only url and alt" do
        node = NodeMaker.image(url)
        node.append_child NodeMaker.text(text_contents)
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
      it "renders with url, title and alt" do
        node = NodeMaker.image(url, title)
        node.append_child NodeMaker.text(text_contents)
        renderer = HTMLRenderer.new
        renderer.render(node).should eq node.render_html
      end
    end
  end

  describe "table elements" do
    markdown = <<-MD
      | foo | bar | fii | bor |
      | --- |:--- |:---:| ---:|
      | baz | bim | biz | bum |
      MD
    root = Cmark.parse_document(markdown, extensions: Extension::Table)
    node = root.first_child.not_nil!

    it "renders" do
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
    it "renders with sourcepos" do
      options = Option::Sourcepos
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with option table_prefer_style_attributes" do
      options = Option::TablePreferStyleAttributes
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
    it "renders with sourcepos and option table_prefer_style_attributes" do
      options = Option::Sourcepos | Option::TablePreferStyleAttributes
      renderer = HTMLRenderer.new(options)
      renderer.render(node).should eq node.render_html(options)
    end
  end

  describe "footnote elements" do
    markdown = <<-MD
      This[^one] is a reference; this[^two] one another; this[^one] the same as the first one.

      [^one]: Reference 1
      [^two]: Reference 2
      MD
    root = Cmark.parse_document(markdown, Option::Footnotes)

    it "renders" do
      renderer = HTMLRenderer.new
      renderer.render(root).should eq root.render_html
    end
    it "renders with sourcepos" do
      renderer = HTMLRenderer.new
      renderer.render(root).should eq root.render_html
    end
  end

  describe "#strikethrough" do
    it "renders" do
      node = NodeMaker.strikethrough
      renderer = HTMLRenderer.new
      renderer.render(node).should eq node.render_html
    end
  end
end