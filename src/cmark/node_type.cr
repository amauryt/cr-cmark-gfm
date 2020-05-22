require "./lib_cmark"

module Cmark
  # Represents the type of a node.
  #
  # If valid, the type can be grouped into several categories:
  # 1) block or inline; 2) Commonmark or GFM; and 3) container or leaf.
  # Use the respective method to check the node type category:
  #   1. `#block?` or `#inline?`
  #   2. `#commonmark?` or `#gfm?`
  #   3. `#container?` or `#leaf?`
  #
  # If the node is _invalid_ it has the type `None`, and all of the previous methods will return false.
  #
  # Commonmark:
  #  - Block types:
  #     - `Document`
  #     - `BlockQuote`
  #     - `List`
  #     - `Item`
  #     - `CodeBlock`
  #     - `HTMLBlock`
  #     - `CustomBlock`
  #     - `Paragraph`
  #     - `Heading`
  #     - `ThematicBreak`
  # - Inline types:
  #     - `Text`
  #     - `Softbreak`
  #     - `Linebreak`
  #     - `Code`
  #     - `HTMLInline`
  #     - `CustomInline`
  #     - `Emph`
  #     - `Strong`
  #     - `Link`
  #     - `Image`
  #
  # GFM:
  #
  #  - Block types:
  #     - `Table`
  #     - `TableRow`
  #     - `TableCell`
  #     - `FootnoteDefinition`
  #  - Inline types:
  #     - `Strikethrough`
  #     - `FootnoteReference`
  #
  # Leaf nodes:
  #
  #  - `HTMLBlock`
  #  - `ThematicBreak`
  #  - `CodeBlock`
  #  - `Text`
  #  - `Softbreak`
  #  - `Linebreak`
  #  - `Code`
  #  - `HTMLInline`
  #
  # NOTE: The GFM syntax extension for tasklists does not create a new node type. That is, a tasklist item
  # has `NodeType::Item`. To check if a given node is a tasklist item use `Node#tasklist_item?`; to set if a
  # list item node represents a tasklist or not use `Node#tasklist_item=`.
  #
  # NOTE: Both footnote elements are part of GFM, but they are not syntax extensions and they
  # are not defined in the GFM spec.
  # Therefore, they can be enabled in so-called *Commonmark-only* methods using `Option::Footnotes`.
  # Normal inconsistencies when trying to define a standard specification‽
  # For more information regarding footnotes in cmark-gfm see [this pull request](https://github.com/github/cmark-gfm/pull/64).
  # To check if an element is part of a syntax extension use `#syntax_extension?`.
  #
  # NOTE: The numeric values of GFM extensions types do not correspond to their counterpart in the C library because
  # these are not predefined constants, they are dynamically registered at runtime.
  enum NodeType
    def block?
      self.value & LibCmark::CMARK_NODE_TYPE_MASK == LibCmark::CMARK_NODE_TYPE_BLOCK
    end

    def inline?
      self.value & LibCmark::CMARK_NODE_TYPE_MASK == LibCmark::CMARK_NODE_TYPE_INLINE
    end

    def syntax_extension?
      # SYNTAX_EXTENSION_MASK = 0x0010
      self.value & 0x0010 == 0x0010
    end

    def gfm?
      syntax_extension? || footnote_definition? || footnote_reference?
    end

    def commonmark?
      !none? && !gfm?
    end

    def leaf?
      text? || softbreak? || linebreak? || code? || html_block? || code_block? || html_inline? || code? || thematic_break?
    end

    def container?
      !none? && !leaf?
    end

    # :nodoc:
    def to_unsafe
      if self.syntax_extension?
        case self
          when .table?
            LibCmark.cmark_node_table
          when .table_row?
            LibCmark.cmark_node_table_row
          when .table_cell?
            LibCmark.cmark_node_table_cell
          when .strikethrough?
            LibCmark.cmark_node_strikethrough
          else
            LibCmark::NodeType::CMARK_NODE_NONE
        end
      else
        LibCmark::NodeType.from_value(self.value)
      end
    end

    # Invalid node
    None                = LibCmark::NodeType::CMARK_NODE_NONE

    # === CommonMark

    # Commonmark / Block / Container
    Document            = LibCmark::NodeType::CMARK_NODE_DOCUMENT
    # Commonmark / Block / Container
    BlockQuote          = LibCmark::NodeType::CMARK_NODE_BLOCK_QUOTE
    # Commonmark / Block / Container
    List                = LibCmark::NodeType::CMARK_NODE_LIST
    # Commonmark / Block / Container
    Item                = LibCmark::NodeType::CMARK_NODE_ITEM
    # Commonmark / Block / Leaf
    CodeBlock           = LibCmark::NodeType::CMARK_NODE_CODE_BLOCK
    # Commonmark / Block / Container
    HTMLBlock           = LibCmark::NodeType::CMARK_NODE_HTML_BLOCK
    # Commonmark / Block / Container
    CustomBlock         = LibCmark::NodeType::CMARK_NODE_CUSTOM_BLOCK
    # Commonmark / Block / Container
    Paragraph           = LibCmark::NodeType::CMARK_NODE_PARAGRAPH
    # Commonmark / Block / Container
    Heading             = LibCmark::NodeType::CMARK_NODE_HEADING
    # Commonmark / Block / Leaf
    ThematicBreak       = LibCmark::NodeType::CMARK_NODE_THEMATIC_BREAK
    # GFM / Block / Container
    FootnoteDefinition  = LibCmark::NodeType::CMARK_NODE_FOOTNOTE_DEFINITION

    # Commonmark / Inline / Leaf
    Text                = LibCmark::NodeType::CMARK_NODE_TEXT
    # Commonmark / Inline / Leaf
    Softbreak           = LibCmark::NodeType::CMARK_NODE_SOFTBREAK
    # Commonmark / Inline / Leaf
    Linebreak           = LibCmark::NodeType::CMARK_NODE_LINEBREAK
    # Commonmark / Inline / Leaf
    Code                = LibCmark::NodeType::CMARK_NODE_CODE
    # Commonmark / Inline / Leaf
    HTMLInline          = LibCmark::NodeType::CMARK_NODE_HTML_INLINE
    # Commonmark / Inline / Container
    CustomInline        = LibCmark::NodeType::CMARK_NODE_CUSTOM_INLINE
    # Commonmark / Inline / Container
    Emph                = LibCmark::NodeType::CMARK_NODE_EMPH
    # Commonmark / Inline / Container
    Strong              = LibCmark::NodeType::CMARK_NODE_STRONG
    # Commonmark / Inline / Container
    Link                = LibCmark::NodeType::CMARK_NODE_LINK
    # Commonmark / Inline / Container
    Image               = LibCmark::NodeType::CMARK_NODE_IMAGE
    # GFM / Inline / Container
    FootnoteReference   = LibCmark::NodeType::CMARK_NODE_FOOTNOTE_REFERENCE

    # === GFM Syntax extensions

    # GFM / Block / Container
    Table               = LibCmark::CMARK_NODE_TYPE_BLOCK | 0x0011
    # GFM / Block / Container
    TableRow            = LibCmark::CMARK_NODE_TYPE_BLOCK | 0x0012
    # GFM / Block / Container
    TableCell           = LibCmark::CMARK_NODE_TYPE_BLOCK | 0x0013

    # GFM / Inline / Container
    Strikethrough       = LibCmark::CMARK_NODE_TYPE_INLINE | 0x0011
  end
end