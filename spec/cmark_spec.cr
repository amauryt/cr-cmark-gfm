require "./spec_helper"

describe Cmark do
  describe "#commonmark_to_html" do
    it "parses commonmark with the default options" do
      markdown = "Hello *world*"
      html = Cmark.commonmark_to_html(markdown)
      html.should eq "<p>Hello <em>world</em></p>\n"
    end
  end

  describe "#document_to_html" do
    it "parses commonmark with the default options and some extensions enabled" do
      markdown = "Hello *world* with ~all~ some of the extensions"
      html = Cmark.document_to_html(markdown, extensions: Cmark::Extension::Strikethrough)
      html.should eq "<p>Hello <em>world</em> with <del>all</del> some of the extensions</p>\n"
    end
  end

  describe "#gfm_to_html" do
    it "parses commonmark with the default options and some extensions enabled" do
      markdown = "Hello *world* with ~some~ all of the extensions"
      html = Cmark.gfm_to_html(markdown)
      html.should eq "<p>Hello <em>world</em> with <del>some</del> all of the extensions</p>\n"
    end
  end

  describe "#parse_commonmark" do
    it "parses markdown as a Cmark::Node" do
      markdown = "Hello *world*"
      node = Cmark.parse_commonmark(markdown)
      node.should be_a(Cmark::Node)
    end
  end

  describe "#parse_document" do
    it "parses markdown as a Cmark::Node" do
      markdown = "Hello *world*"
      node = Cmark.parse_document(markdown)
      node.should be_a(Cmark::Node)
    end
  end
end
