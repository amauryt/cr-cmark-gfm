require "uri"

module Cmark
  class HTMLRenderer < Renderer
    macro conditional_out_url_encoding
      {% verbatim do %}
        if url && (@options.unsafe? || !(UNSAFE_URL_REGEX === url))
          {% if compare_versions(Crystal::VERSION, "1.2.0") < 0 %}
            out URI.encode(url)
          {% else %}
            out URI.encode_path(url)
          {% end %}
        end
      {% end %}
    end

    @footnote_index = 0
    @written_footnote_index = 0

    @table_needs_closing_table_body = false
    @table_in_table_header = false

    def document(node, entering)
      if !entering && @written_footnote_index > 0
        out "</ol>\n</section>\n"
      end
    end

    def block_quote(node, entering)
      if entering
        out "<blockquote"
        sourcepos node
        out ">\n"
      else
        cr
        out "</blockquote>\n"
      end
    end

    def list(node, entering)
      if entering
        cr
        if node.list_type.bullet?
          out "<ul"
        else
          out "<ol"
          out %{ start="#{node.list_start}"} if node.list_start > 1
        end
        sourcepos node
        out ">\n"
      else
        out node.list_type.bullet? ? "</ul>\n" : "</ol>\n"
      end
    end

    def item(node, entering)
      if (entering)
        cr
        out "<li"
        sourcepos node
        out ">"
        tasklist_item_inner(node, entering) if node.tasklist_item?
      else
        tasklist_item_inner(node, entering) if node.tasklist_item?
        out "</li>\n"
      end
    end

    def code_block(node)
      cr
      out "<pre"
      sourcepos node
      fence_info = node.fence_info

      if fence_info.bytesize.zero?
        out "><code>"
      else
        tags = fence_info.split(' ', remove_empty: true)
        if @options.github_pre_lang?
          out %( lang="#{escape_html(tags.shift)})
          tags.each { |tag| out %(" data-meta="#{escape_html(tag)}) } if @options.full_info_string?
          out %("><code>)
        else
          out %(><code class="language-#{escape_html(tags.shift)})
          tags.each { |tag| out %(" data-meta="#{escape_html(tag)}) } if @options.full_info_string?
          out %(">)
        end
      end
      out escape_html(node.literal)
      out "</code></pre>\n"
    end

    def html_block(node)
      cr
      if !@options.unsafe?
        out "<!-- raw HTML omitted -->"
      elsif @extensions.tagfilter?
        out filter_tags(node.literal)
      else
        out node.literal
      end
      cr
    end

    def custom_block(node, entering)
      cr
      if entering
        out node.on_enter
      else
        out node.on_exit
      end
      cr
    end

    def paragraph(node, entering)
      grandparent = node.grandparent
      tight = false
      tight = grandparent.list_tight? if !grandparent.nil? && grandparent.type.list?
      return if tight

      if entering
        cr
        out "<p"
        sourcepos node
        out ">"
      else
        if (node.parent.try &.type.footnote_definition?) && node.next.nil?
          out " "
          print_footnote_backref(node.parent.not_nil!)
        end
        out "</p>\n"
      end
    end

    def heading(node, entering)
      if entering
        cr
        out "<h#{node.heading_level}"
        sourcepos node
        out ">"
      else
        out "</h#{node.heading_level}"
        out ">\n"
      end
    end

    def thematic_break(node)
      cr
      out "<hr"
      sourcepos node
      out " />\n"
    end

    def footnote_definition(node, entering)
      if entering
        if @footnote_index.zero?
          out %(<section class="footnotes" data-footnotes>\n<ol>\n)
        end
        @footnote_index += 1
        def_literal = escape_html(node.footnote_definition_literal)
        out %(<li id="fn-#{def_literal}">\n)
      else
        out "\n" if print_footnote_backref(node)
        out "</li>\n"
      end
    end

    def text(node)
      out escape_html(node.literal)
    end

    def softbreak(node)
      case @options
      when .hardbreaks?
        out "<br />\n"
      when .nobreaks?
        out " "
      else
        out "\n"
      end
    end

    def linebreak(node)
      out "<br />\n"
    end

    def code(node)
      out "<code>"
      out escape_html(node.literal)
      out "</code>"
    end

    def html_inline(node)
      if !@options.unsafe?
        out "<!-- raw HTML omitted -->"
      elsif @extensions.tagfilter?
        out filter_tags(node.literal)
      else
        out node.literal
      end
    end

    def custom_inline(node, entering)
      if entering
        out node.on_enter
      else
        out node.on_exit
      end
    end

    def emph(node, entering)
      if entering
        out "<em>"
      else
        out "</em>"
      end
    end

    def strong(node, entering)
      if entering
        out "<strong>"
      else
        out "</strong>"
      end
    end

    def link(node, entering)
      if entering
        url = node.url
        title = node.title
        out %(<a href=")
        conditional_out_url_encoding
        unless title.try &.empty?
          out %(" title=")
          out escape_html(title)
        end
        out %(">)
      else
        out "</a>"
      end
    end

    def image(node, entering)
      if entering
        url = node.url
        out %(<img src=")
        conditional_out_url_encoding
        out %(" alt=")
      else
        title = node.title
        out %(" title="#{title}) unless title.empty?
        out %(" />)
      end
    end

    def footnote_inline(node, entering)
      if entering
        parent_def_literal = escape_html(node.footnote_parent_definition_literal)
        out %(<sup class="footnote-ref"><a href="#fn-#{parent_def_literal}" id="fnref-#{parent_def_literal})
        out %(-#{node.footnote_reference_index}) if node.footnote_reference_index > 1
        out %(" data-footnote-ref>)
        out node.literal
        out "</a></sup>"
      end
    end

    def table(node, entering)
      if entering
        cr
        out "<table"
        sourcepos node
        out ">"
        @table_needs_closing_table_body = false
      else
        if @table_needs_closing_table_body
          cr
          out "</tbody>"
          cr
        end

        @table_needs_closing_table_body = false
        cr
        out "</table>"
        cr
      end
    end

    def table_row(node, entering)
      if entering
        cr
        if node.table_row_header?
          @table_in_table_header = true
          out "<thead>"
          cr
        elsif !@table_needs_closing_table_body
          out "<tbody>"
          cr
          @table_needs_closing_table_body = true
        end
        out "<tr"
        sourcepos node
        out ">"
      else
        cr
        out "</tr>"
        if node.table_row_header?
          cr
          out "</thead>"
          @table_in_table_header = false
        end
      end
    end

    def table_cell(node, entering)
      if entering
        cr
        out @table_in_table_header ? "<th" : "<td"
        alignment = node.table_cell_alignment
        unless alignment.none?
          if @options.table_prefer_style_attributes?
            out %( style="text-align: #{alignment.to_s.downcase}")
          else
            out %( align="#{alignment.to_s.downcase}")
          end
        end
        sourcepos node
        out ">"
      else
        out(@table_in_table_header ? "</th>" : "</td>")
      end
    end

    def strikethrough(node, entering)
      out(entering ? "<del>" : "</del>")
    end

    # === Auxiliary methods

    def tasklist_item_inner(node, entering)
      if entering
        if node.tasklist_item_checked?
          out %(<input type="checkbox" checked="" disabled="" /> )
        else
          out %(<input type="checkbox" disabled="" /> )
        end
      end
    end

    def sourcepos(node)
      if @options.sourcepos?
        out %( data-sourcepos="#{node.start_line}:#{node.start_column}-#{node.end_line}:#{node.end_column}")
      end
    end

    def print_footnote_backref(node) : Bool
      return false if @written_footnote_index >= @footnote_index
      @written_footnote_index = @footnote_index
      def_literal = escape_html(node.footnote_definition_literal)
      out %(<a href="#fnref-#{def_literal}" class="footnote-backref" data-footnote-backref aria-label="Back to content">↩</a>)
      def_count = node.footnote_definition_count
      if def_count > 1
        (2..def_count).each do |i|
          out %( <a href="#fnref-#{def_literal}-#{i}" class="footnote-backref" data-footnote-backref aria-label="Back to content">↩)
          out %(<sup class="footnote-ref">#{i}</sup></a>)
        end
      end
      true
    end
  end
end
