require "../spec_helper"
include Cmark

describe Event do
  describe "#modifiable?" do
    leaf_node = NodeMaker.text("Example")
    container_node = NodeMaker.strong

    it "returns true when the event is entering a leaf node" do
      event = Event.new(true, leaf_node)
      event.modifiable?.should be_true
    end
    it "returns false when the event is entering a container node" do
      event = Event.new(true, container_node)
      event.modifiable?.should be_false
    end
    it "returns true when the event is exiting a container node" do
      event = Event.new(false, container_node)
      event.modifiable?.should be_true
    end
  end

end