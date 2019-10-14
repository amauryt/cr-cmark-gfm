require "./lib_cmark"

module Cmark
  # A flag enum for rendering and parsing options, with `None` being the default.
  #
  # Options affecting rendering:
  # * `Sourcepos`
  # * `Hardbreaks`
  # * `Unsafe`
  # * `Nobreaks`
  #
  # Options affecting parsing:
  # * `ValidateUTF8`
  # * `Smart`
  # * `GithubPreLang`
  # * `LiberalHTMLTag`
  # * `Footnotes`
  # * `StrikethroughDoubleTilde`
  # * `TablePreferStyleAttributes`
  # * `FullInfoString`
  #
  # You can easily combine options like this:
  # ```
  # options = Option.flags(Unsafe, Nobreaks, ValidateUTF8, Smart)
  # ```
  @[Flags]
  enum Option
    # === Options affecting rendering

    # Include a 'data-sourcepos' attribute on all block elements.
    Sourcepos = LibCmark::CMARK_OPT_SOURCEPOS

    # Render 'softbreak' elements as hard line breaks.
    Hardbreaks = LibCmark::CMARK_OPT_HARDBREAKS

    # Render raw HTML and unsafe links.
    #
    # It applies to 'javascript', 'vbscript', 'file', and 'data',
    # except for 'image/png', 'image/gif', 'image/jpeg', or
    # 'image/webp' mime types.
    #
    # By default, raw HTML is replaced by a placeholder HTML comment.
    # Unsafe links are replaced by empty strings.
    Unsafe = LibCmark::CMARK_OPT_UNSAFE

    # Render 'softbreak' elements as spaces.
    Nobreaks = LibCmark::CMARK_OPT_NOBREAKS


    # === Options affecting parsing


    # Validate UTF-8 in the input before parsing, replacing illegal
    # sequences with the replacement character U+FFFD.
    ValidateUTF8 = LibCmark::CMARK_OPT_VALIDATE_UTF8

    # Convert straight quotes to curly, --- to em dashes, -- to en dashes.
    Smart = LibCmark::CMARK_OPT_SMART

    # Use GitHub-style '<pre lang="x">' tags for code blocks instead
    # of '<pre><code class="language-x">'.
    GithubPreLang = LibCmark::CMARK_OPT_GITHUB_PRE_LANG

    # Be liberal in interpreting inline HTML tags.
    LiberalHTMLTag = LibCmark::CMARK_OPT_LIBERAL_HTML_TAG

    # Parse footnotes.
    Footnotes = LibCmark::CMARK_OPT_FOOTNOTES

    # Only parse strikethroughs if surrounded by exactly 2 tildes.
    StrikethroughDoubleTilde  = LibCmark::CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE

    # Use style attributes to align table cells instead of align attributes.
    TablePreferStyleAttributes = LibCmark::CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES

    # Include the remainder of the info string in code blocks in a separate attribute.
    FullInfoString = LibCmark::CMARK_OPT_FULL_INFO_STRING

  end
end