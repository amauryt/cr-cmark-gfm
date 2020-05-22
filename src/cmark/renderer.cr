module Cmark
  # The base renderer class from which to inherit for full custom node rendering.
  abstract class Renderer
    private UNSAFE_PROTOCOL_REGEX = /^javascript:|vbscript:|file:|data:/i
    private UNSAFE_DATA_PROTOCOL_REGEX = /^data:image\/(?:png|gif|jpeg|webp)/i
    private UNSAFE_URL_REGEX = Regex.union(UNSAFE_PROTOCOL_REGEX, UNSAFE_DATA_PROTOCOL_REGEX)

    private TAGFILTER_REGEX = Regex.new(
      "<(title|textarea|style|xmp|iframe|noembed|noframes|script|plaintext)(?=\s|>|/>)",
      Regex::Options::IGNORE_CASE | Regex::Options::EXTENDED
    )

    private ESCAPES = {
      '&'   => "&amp;",
      '<'   => "&lt;",
      '>'   => "&gt;",
      '"'   => "&quot;",
    }

    def initialize(@options = Option::None, @extensions = Extension::None)
      @output = String::Builder.new
    end

    # Prints to output
    def out(str)
      @output << str
    end


    def escape_html(content : String)
      has_escape_html_char?(content) ? content.gsub(ESCAPES) : content
    end

    # Prints a '\n' in output if its last character in output is not already '\n'
    def cr
      # '\n'.ord # => 0x0A
      if @output.bytesize > 0 && @output.buffer[@output.bytesize - 1] != 0x0A
        @output.write_byte 0x0A
      end
    end

    private def has_escape_html_char?(content : String)
      content.each_byte do |byte|
        return true if byte === '&' || byte === '"' || byte === '<' || byte === '>'
      end
      false
    end

    private def has_filter_html_char?(content : String)
      content.each_byte do |byte|
        return true if byte === '<'
      end
      false
    end

    def filter_tags(content : String)
      content.gsub(TAGFILTER_REGEX,"&lt;\\1")
    end

    def render(root : Node) : String
      # ensure that we don't use a finalized @output
      @output = String::Builder.new if @output.bytesize > 0
      iterator = EventIterator.new(root)
      iterator.each do |event|
        node = event.node
        entering = event.enter?

        case node.type

          # Block
          when NodeType::Document
            document(node, entering)
          when NodeType::BlockQuote
            block_quote(node, entering)
          when NodeType::List
            list(node, entering)
          when NodeType::Item
            item(node, entering)
          when NodeType::CodeBlock
            code_block(node)
          when NodeType::HTMLBlock
            html_block(node)
          when NodeType::CustomBlock
            custom_block(node, entering)
          when NodeType::Paragraph
            paragraph(node, entering)
          when NodeType::Heading
            heading(node, entering)
          when NodeType::ThematicBreak
            thematic_break(node)
          when NodeType::FootnoteDefinition
            footnote_definition(node, entering)

          # Inline
          when NodeType::Text
            text(node)
          when NodeType::Softbreak
            softbreak(node)
          when NodeType::Linebreak
            linebreak(node)
          when NodeType::Code
            code(node)
          when NodeType::HTMLInline
            html_inline(node)
          when NodeType::CustomInline
            custom_inline(node, entering)
          when NodeType::Emph
            emph(node, entering)
          when NodeType::Strong
            strong(node, entering)
          when NodeType::Link
            link(node, entering)
          when NodeType::Image
            image(node, entering)
          when NodeType::FootnoteReference
            footnote_inline(node, entering)

          # Extensions
          when NodeType::Table
            table(node, entering)
          when NodeType::TableRow
            table_row(node, entering)
          when NodeType::TableCell
            table_cell(node, entering)
          when NodeType::Strikethrough
            strikethrough(node, entering)
          else
            raise Cmark::Error.new("Invalid rendering for #{node}.")

        end
      end
      @output.to_s
    end
  end
end

require "./renderers/*"