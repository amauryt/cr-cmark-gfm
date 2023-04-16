# cr-cmark-gfm

[![Crystal CI](https://github.com/amauryt/cr-cmark-gfm/actions/workflows/crystal.yml/badge.svg)](https://github.com/amauryt/cr-cmark-gfm/actions/workflows/crystal.yml)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://amauryt.github.io/cr-cmark-gfm/)

Crystal C bindings for cmark-gfm, with support for Github Flavored Markdown (**v0.29.0.gfm.8**). For more information regarding the available options and extensions see the official [GFM spec documentation](https://github.github.com/gfm/).


Features:

  - Simple parsing and rendering of markdown content
  - Render any node of the markdown AST in the following formats:
    - HTML
    - XML
    - Plaintext
    - Commonmark (including GFM-only nodes)
    - Groff man pages
    - LaTeX
  - Create custom renderers or customize the included crystal HTML renderer, which outputs the same HTML as the library's C renderer
  - Getters and setters for almost all of the properties of AST nodes
  - Tree traversal and manipulation
  - Directly create and customize nodes

## Installation

Add the dependency to your `shard.yml` and then run `shards install`:

```yaml
dependencies:
  cmark:
    github: amauryt/cr-cmark-gfm
    version: ~> 0.1.2
```

This will automatically clone the cmark-gfm repository and compile both `libcmark-gfm` and `libcmark-gfm-extensions`, which can then be statically linked.

## Usage

The `Cmark` module offers high-level parsing and rendering of markdown content, be it Commonmark-only, full GFM, or partially GFM.

If the content is Commonmark-only use the respective _commonmark_  parsing and HTML rendering methods for the best performance. If all of the GFM extensions must be enabled use the _gfm_ methods. For partial support of GFM extensions use the more generic _document_ methods.

```crystal
require "cmark"

options = Option.flags(Nobreaks, ValidateUTF8) # deafult is Option::None
extensions = Extension.flags(Table, Tasklist)  # default is Extension::None

commonmark_only = File.read("commonmark_only.md")
full_gfm = File.read("full_gfm.md")
partially_gfm = File.read("partially_gfm.md")

# Direct parsing and rendering

commonmark_only_html  = Cmark.commonmark_to_html(commonmark_only, options)
full_gfm_html         = Cmark.gfm_to_html(full_gfm, options)
partially_gfm_html    = Cmark.document_to_html(partially_gfm, options, extensions)

# Parse to obtain a document node for further processing

commonmark_only_node  = Cmark.parse_commonmark(commonmark_only, options)
full_gfm_node         = Cmark.parse_gfm(full_gfm, options)
partially_gfm_node    = Cmark.parse_document(partially_gfm, options, extensions)
```

### Node creation and rendering

```crystal
require "cmark"
include Cmark

contents = NodeMaker.strong
contents.append_child NodeMaker.text("click here")
node = NodeMaker.link(url: "http://example.com", title: "Example")
node.append_child(contents)

node.type.link? # => true
node.url # => http://example.com
node.title # => "Example"
node.title = "My Example"

node.render_commonmark # => [**click here**](http://example.com "My Example")
node.render_plaintext # => click here
```

### Tree traversal and manipulation

```crystal
# Using the node from the previous example

node.previous # => nil
node.first_child # => <Cmark::Node::Strong>
last_child =  node.last_child.not_nil!
last_child == node.first_child # => true
last_child.next # => <Cmark::Node::Text>

iterator = EventIterator.new(node)

iterator.each do |event|
  node = event.node
  if event.enter?
    puts "entering node"
  end
  if event.modifiable? && node.type.strong?
    # Transform strong text into unformatted text
    text_node = node.first_child.not_nil!
    node.parent.not_nil!.prepend_child(text_node)
    node.unlink
  end
end

node.render_commonmark # => [click here](http://example.com "My Example")
```

### Custom rendering
```crystal
class MyHTMLRenderer < Cmark::HTMLRenderer
  # Container nodes receive `node` and `entering`
  def strong(node, entering)
    if entering
      out "<b>"
    else
      out "</b>"
    end
  end

  # Leaf nodes only receive `node`
  def text(node)
    out node.literal.gsub("click", "don't click")
  end
end

# Using the node from the "Node creation and rendering" example

options = Option.flags(Nobreaks, ValidateUTF8) # default is Option::None
extensions = Extension.flags(Table, Tasklist) # default is Extension::None

renderer = MyHTMLRenderer.new(options, extensions)
html = renderer.render(node)
html # => <a href="http://example.com" title="My Example"><b>don't click here</b></a>
```

## Alternatives

Other alternatives (from which this shard took inspiration) are:

* [markd](https://github.com/icyleaf/markd): A pure Crystal port of [commonmark.js](https://github.com/jgm/commonmark.js). Compliant to Commonmark v0.29, but it has no GFM support.
* [crystal-cmark](https://github.com/ysbaddaden/crystal-cmark): Minimal parsing and rendering C bindings with [cmark](https://github.com/commonmark/cmark) v0.30.2 but without GFM support.
* [crystal-cmark-gfm](https://github.com/mamantoha/crystal-cmark-gfm): Minimal C bindings for parsing and rendering with the latest commit of [cmark-gfm](https://github.com/github/cmark-gfm) (v0.29.0.gfm.x)

## Contributing

1. Fork it (<https://github.com/amauryt/cr-cmark-gfm/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Amaury Trujillo](https://github.com/amauryt) - creator and maintainer
- [Anton Maminov](https://github.com/mamantoha) - contributor