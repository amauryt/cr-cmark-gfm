require "../spec_helper"
include Cmark

describe EventIterator do
  describe "#rewind" do
    it "rewinds to the initial node event" do
      root = Cmark.parse_commonmark("Hello *world*")
      iterator = EventIterator.new(root)
      first_wind = iterator.to_a
      first_wind.size.should eq 8
      second_wind = iterator.rewind.to_a
      second_wind.first.should eq first_wind.first
      second_wind.size.should eq first_wind.size
    end
  end

  context "custom HTML render" do
    it "allows custom HTML rendering" do
      root = Cmark.parse_commonmark("Hello *world*")
      iterator = EventIterator.new(root)
      html = String.build do |html|
        iterator.each do |event|
          node = event.node
          if node.type.leaf?
            html << node.render_html
          elsif node.type.paragraph?
            html << (event.enter? ? "<div>" : "</div>")
          elsif node.type.emph?
            html << (event.enter? ? "<i>" : "</i>")
          end
        end
        html << "\n"
      end
      html.should eq "<div>Hello <i>world</i></div>\n"
    end
  end
end