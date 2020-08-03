require "./cmark/**"

Cmark::LibCmark.cmark_gfm_core_extensions_ensure_registered()

# This module offers high-level parsing and rendering of markdown content, be it Commonmark-only, full GFM, or partially GFM.
#
# If the content is Commonmark-only use the respective _commonmark_  parsing and
# HTML rendering methods for the best performance.
# If all of the GFM extensions must be enabled use the _gfm_ methods.
# For partial support of GFM extensions use the more generic _document_ methods.
module Cmark
  # Renders a Commonmark-only text as HTML.
  def self.commonmark_to_html(text : String, options = Option::None) : String
    len = text.bytesize
    result = LibCmark.cmark_markdown_to_html(text, len, options)
    String.new(result)
  end

  # Renders commonmark text with all of the GFM extensions enabled as HTML.
  def self.gfm_to_html(text : String, options = Option::None) : String
    self.document_to_html(text, options, Extension::All)
  end

  # Renders commonmark text as HTML.
  def self.document_to_html(text : String, options = Option::None, extensions = Extension::None) : String
    allocator = LibCmark.cmark_get_default_mem_allocator()
    document = self.parse_document_with_allocator(text, options, extensions, allocator)
    html = document.render_html(options, extensions)
    html
  end

  # Parses a Commonmark-only document text.
  def self.parse_commonmark(text : String, options = Option::None) : Node
    len = text.bytesize
    node_p = LibCmark.cmark_parse_document(text, len, options)
    Node.new(node_p)
  end

  # Parses a commonmark document text.
  def self.parse_document(text : String, options = Option::None, extensions = Extension::None) : Node
    allocator = LibCmark.cmark_get_default_mem_allocator()
    self.parse_document_with_allocator(text, options, extensions, allocator)
  end

  # Parses a commonmark document text with all of the GFM extensions enabled.
  def self.parse_gfm(text : String, options = Option::None) : Node
    self.parse_document(text, options, Extension::All)
  end

  private def self.register_extensions(parser_p : LibCmark::CmarkParser*, extensions : Extension)
    extensions.each do |ext|
      ext_name = ext.to_s.downcase
      lib_ext_p = LibCmark.cmark_find_syntax_extension(ext_name)
      if (lib_ext_p.null?)
        LibCmark.cmark_parser_free(parser_p)
        raise Cmark::Error.new("Invalid syntax extension `#{ext_name}`.")
      else
        result = LibCmark.cmark_parser_attach_syntax_extension(parser_p, lib_ext_p)
        if result.zero?
          LibCmark.cmark_parser_free(parser_p)
          raise Cmark::Error.new("Could not attach syntax extension `#{ext_name}`.")
        end
      end
    end
  end

  private def self.parse_document_with_allocator(text : String, options : Option, extensions : Extension, allocator : LibCmark::CmarkMem*) : Node
    parser_p = LibCmark.cmark_parser_new_with_mem(options, allocator)
    self.register_extensions(parser_p, extensions) unless extensions.none?
    len = text.bytesize
    LibCmark.cmark_parser_feed(parser_p, text, len)
    node_p = LibCmark.cmark_parser_finish(parser_p)
    LibCmark.cmark_parser_free(parser_p)
    Node.new(node_p)
  end

end