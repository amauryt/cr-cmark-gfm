require "../spec_helper"
include Cmark

describe NodeType do
  describe "#inline?" do
    it "returns true for inline types" do
      NodeType::Text.inline?.should be_true
    end
    it "returns false for block types" do
      NodeType::Document.inline?.should be_false
    end
    it "returns false for extension block types" do
      NodeType::Table.inline?.should be_false
    end
    it "returns false for invalid types" do
      NodeType::None.inline?.should be_false
    end
  end

  describe "#block?" do
    it "returns true for block types" do
      NodeType::BlockQuote.block?.should be_true
    end
    it "returns true for extension block types" do
      NodeType::Table.block?.should be_true
    end
    it "returns false for inline types" do
      NodeType::Link.block?.should be_false
    end
    it "returns false for invalid types" do
      NodeType::None.block?.should be_false
    end
  end

  describe "#gfm?" do
    it "returns true for extension block types" do
      NodeType::Table.gfm?.should be_true
    end
    it "returns true for inline block types" do
      NodeType::Strikethrough.gfm?.should be_true
    end
    it "returns false for commonmark block types" do
      NodeType::BlockQuote.gfm?.should be_false
    end
    it "returns false for commonmark inline types" do
      NodeType::Link.gfm?.should be_false
    end
    it "returns false for invalid types" do
      NodeType::None.gfm?.should be_false
    end
  end

  describe "#commonmark?" do
    it "returns false for extension block types" do
      NodeType::Table.commonmark?.should be_false
    end
    it "returns false for inline block types" do
      NodeType::Strikethrough.commonmark?.should be_false
    end
    it "returns true for commonmark block types" do
      NodeType::BlockQuote.commonmark?.should be_true
    end
    it "returns true for commonmark inline types" do
      NodeType::Link.commonmark?.should be_true
    end
    it "returns false for invalid types" do
      NodeType::None.commonmark?.should be_false
    end
  end

  describe "#leaf?" do
    it "returns true for leaf types" do
      NodeType::Text.leaf?.should be_true
    end
    it "returns false for container types" do
      NodeType::Paragraph.leaf?.should be_false
    end
    it "returns false for invalid types" do
      NodeType::None.leaf?.should be_false
    end
  end

  describe "#container?" do
    it "returns false for leaf types" do
      NodeType::Text.container?.should be_false
    end
    it "returns true for container types" do
      NodeType::Paragraph.container?.should be_true
    end
    it "returns false for invalid types" do
      NodeType::None.container?.should be_false
    end
  end

end