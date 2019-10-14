module Cmark
  @[Link(ldflags: "#{__DIR__}/../../ext/*.a")]
  lib LibCmark

    # Options affecting rendering

    CMARK_OPT_DEFAULT = 0
    CMARK_OPT_SOURCEPOS = (1 << 1)
    CMARK_OPT_HARDBREAKS = (1 << 2)
    CMARK_OPT_SAFE = (1 << 3) # No effect. "Safe" mode is now the default, see `CMARK_OPT_UNSAFE`.
    CMARK_OPT_UNSAFE = (1 << 17)
    CMARK_OPT_NOBREAKS = (1 << 4)

    # Options affecting parsing

    CMARK_OPT_NORMALIZE = (1 << 8)
    CMARK_OPT_VALIDATE_UTF8 = (1 << 9)
    CMARK_OPT_SMART = (1 << 10)
    CMARK_OPT_GITHUB_PRE_LANG = (1 << 11)
    CMARK_OPT_LIBERAL_HTML_TAG = (1 << 12)
    CMARK_OPT_FOOTNOTES = (1 << 13)
    CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE = (1 << 14)
    CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES = (1 << 15)
    CMARK_OPT_FULL_INFO_STRING = (1 << 16)

    MAXBACKTICKS = 80
    MAXBACKTICKS_PLUS_ONE = MAXBACKTICKS + 1

    # For booleans defined with <stdbool.h>
    alias CBool = LibC::Int
    alias FILE = Void*
    alias CmarkInlineParser = Subject

    # See https://github.com/commonmark/cmark/blob/master/src/buffer.h
    alias BufsizeT = Int32

    struct CmarkSyntaxExtension
      last_block_matches : CmarkMatchBlockFunc
      try_opening_block : CmarkOpenBlockFunc
      match_inline : CmarkMatchInlineFunc
      insert_inline_from_delim : CmarkInlineFromDelimFunc
      special_inline_chars : CmarkLinkedList*
      name : LibC::Char*
      priv : Void*
      emphasis: CBool
      free_function : CmarkFreeFunc
      get_type_string_func : CmarkGetTypeStringFunc
      can_contain_func : CmarkCanContainFunc
      contains_inlines_func : CmarkContainsInlinesFunc
      commonmark_render_func : CmarkCommonRenderFunc
      plaintext_render_func : CmarkCommonRenderFunc
      latex_render_func : CmarkCommonRenderFunc
      xml_attr_func : CmarkXMLAttrFunc
      man_render_func : CmarkCommonRenderFunc
      html_render_func : CmarkHTMLRenderFunc
      html_filter_func : CmarkHTMLFilterFunc
      postprocess_func : CmarkPostprocessFunc
      opaque_alloc_func : CmarkOpaqueAllocFunc
      opaque_free_func : CmarkOpaqueFreeFunc
      commonmark_escape_func : CmarkCommonmarkEscapeFunc
    end

    struct CmarkStrbuf
      mem : CmarkMem*
      ptr : LibC::UChar*
      asize : BufsizeT
      size : BufsizeT
    end

    struct CmarkChunk
      data : LibC::UChar*
      len : BufsizeT
      alloc : BufsizeT
    end

    struct CmarkMem
      c : (LibC::SizeT, LibC::SizeT) -> Void* # Default `calloc`
      r : (Void*, LibC::SizeT) -> Void* # Default `realloc`
      f : Void* -> Void # Default `free`
    end

    struct CmarkList
      list_type : ListType
      marker_offset : LibC::Int
      padding : LibC::Int
      start : LibC::Int
      delimiter : DelimType
      bullet_char : LibC::UChar
      tight : CBool
      checked : CBool
    end

    struct CmarkCode
      info : CmarkChunk
      literal : CmarkChunk
      fence_length : UInt8
      fence_offset : UInt8
      fence_char : LibC::UChar
      fenced : Int8
    end

    struct CmarkHeading
      level : LibC::Int
      setext : CBool
    end

    struct CmarkLink
      url : CmarkChunk
      title : CmarkChunk
    end

    struct CmarkCustom
      on_enter : CmarkChunk
      on_exit : CmarkChunk
    end

    struct CmarkNode
      content : CmarkStrbuf

      next : CmarkNode*
      prev : CmarkNode*
      parent : CmarkNode*
      first_child : CmarkNode*
      last_child : CmarkNode*

      user_data : Void*
      user_data_free_func: CmarkFreeFunc

      start_line : LibC::Int
      start_column : LibC::Int
      end_line : LibC::Int
      end_column : LibC::Int
      internal_offset : LibC::Int
      type : UInt16
      flags : UInt16

      extension: CmarkSyntaxExtension*

      _as : CmarkNodeAsUnion
    end

    union CmarkNodeAsUnion
      literal : CmarkChunk
      list : CmarkList
      code : CmarkCode
      heading : CmarkHeading
      link : CmarkLink
      custom : CmarkCustom
      html_block_type : LibC::Int
      opaque : Void*
    end

    struct CmarkLinkedList
      next : CmarkLinkedList*
      data : Void*
    end

    struct CmarkMapEntry
      next : CmarkMapEntry*
      label : LibC::UChar*
      age : LibC::UInt
    end

    struct CmarkMap
      mem : CmarkMem*
      refs : CmarkMapEntry*
      sorted : CmarkMapEntry**
      size : LibC::UInt
      free : CmarkMapFreeF
    end

    struct CmarkParser
      mem : CmarkMem*
      refmap : CmarkMap*
      root : CmarkNode*
      current : CmarkNode*
      line_number : LibC::Int
      offset : BufsizeT
      column : BufsizeT
      first_nonspace : BufsizeT
      first_nonspace_column : BufsizeT
      thematic_break_kill_pos : BufsizeT
      indent : LibC::Int
      blank : CBool
      partially_consumed_tab : CBool
      curline : CmarkStrbuf
      last_line_length : BufsizeT
      linebuf : CmarkStrbuf
      options : LibC::Int
      last_buffer_ended_with_cr : CBool
      syntax_extensions : CmarkLinkedList*
      inline_syntax_extensions : CmarkLinkedList*
      backslash_ispunct : CmarkIspunctFunc
    end

    struct Bracket
      previous : Bracket*
      previous_delimiter : Delimiter*
      inl_text : CmarkNode*
      position : BufsizeT
      image : CBool
      active : CBool
      bracket_after : CBool
    end

    struct Subject
      mem : CmarkMem*
      input : CmarkChunk
      line : LibC::Int
      pos: BufsizeT
      block_offset : LibC::Int
      column_offset : LibC::Int
      refmap : CmarkMap *
      last_delim : Delimiter*
      last_bracket : Bracket*
      backticks : BufsizeT[MAXBACKTICKS_PLUS_ONE]
      scanned_for_backticks : CBool
    end

    struct Delimiter
      previous : Delimiter*
      next : Delimiter*
      inl_text : CmarkNode*
      length : BufsizeT
      delim_char : LibC::UChar
      can_open : LibC::Int
      can_close : LibC::Int
    end

    struct CmarkIterState
      ev_type : EventType
      node : CmarkNode*
    end

    struct CmarkIter
      mem : CmarkMem*
      root : CmarkNode*
      cur : CmarkIterState
      next : CmarkIterState
    end

    struct CmarkRenderer
      mem : CmarkMem*
      buffer : CmarkStrbuf*
      prefix : CmarkStrbuf*
      column : LibC::Int
      width : LibC::Int
      need_cr : LibC::Int
      last_breakable : BufsizeT
      begin_line : CBool
      begin_content : CBool
      no_linebreaks : CBool
      in_tight_list_item : CBool
      outc : ((CmarkRenderer*, CmarkNode*, Escaping, Int32, LibC::UChar) -> Void)*
      cr : ((CmarkRenderer*) -> Void)*
      blankline : ((CmarkRenderer*) -> Void)*
      out : ((CmarkRenderer*, CmarkNode*, LibC::Char*, CBool, Escaping) -> Void)*
      footnote_ix : LibC::UInt
    end

    struct CmarkHTMLRenderer
      html : CmarkStrbuf*
      plain : CmarkNode*
      filter_extensions : CmarkLinkedList*
      footnote_ix : LibC::UInt
      written_footnote_ix : LibC::UInt
      opaque : Void*
    end

    struct CmarkFootnote
      entry : CmarkMapEntry
      node : CmarkNode*
      ix : LibC::UInt
    end


    # Simple interface

    fun cmark_markdown_to_html(text : LibC::Char*, len : LibC::SizeT, options : LibC::Int) : LibC::Char*

    # Custom memory allocator support
    fun cmark_get_default_mem_allocator() : CmarkMem*
    fun cmark_get_arena_mem_allocator() : CmarkMem*
    fun cmark_arena_reset() : Void

    #Linked List

    fun cmark_llist_append(mem : CmarkMem*, head : CmarkLinkedList*, data : Void*) : CmarkLinkedList*
    fun cmark_llist_free_full(mem : CmarkMem*, head : CmarkLinkedList*, free_func : CmarkFreeFunc)
    fun cmark_llist_free(mem : CmarkMem*, head : CmarkLinkedList*)

    # Creating and Destroying Nodes

    fun cmark_node_new(type : NodeType) : CmarkNode*
    fun cmark_node_new_with_mem(type : NodeType, mem: CmarkMem*) : CmarkNode* # be sure to use the same allocator for every node in a tree!!
    fun cmark_node_new_with_mem_and_ext(type : NodeType, mem: CmarkMem*, extensions: CmarkSyntaxExtension*) : CmarkNode*
    fun cmark_node_free(node : CmarkNode*) : Void

    # Tree Traversal

    fun cmark_node_next(node : CmarkNode*) : CmarkNode*
    fun cmark_node_previous(node : CmarkNode*) : CmarkNode*
    fun cmark_node_parent(node : CmarkNode*) : CmarkNode*
    fun cmark_node_first_child(node : CmarkNode*) : CmarkNode*
    fun cmark_node_last_child(node : CmarkNode*) : CmarkNode*

    # Iterator

    fun cmark_iter_new(root : CmarkNode*) : CmarkIter*
    fun cmark_iter_free(iter : CmarkIter*) : Void
    fun cmark_iter_next(iter : CmarkIter*) : EventType
    fun cmark_iter_get_node(iter : CmarkIter*) : CmarkNode*
    fun cmark_iter_get_event_type(iter : CmarkIter*) : EventType
    fun cmark_iter_get_root(iter : CmarkIter*) : CmarkNode*
    fun cmark_iter_reset(iter : CmarkIter*, current : CmarkNode*, envent_type: EventType) : Void

    # Accessors

    fun cmark_node_get_user_data(node: CmarkNode*) : Void*
    fun cmark_node_set_user_data(node: CmarkNode*, user_data : Void*) : CBool
    fun cmark_node_set_user_data_free_func(node: CmarkNode*, free_func : CmarkFreeFunc) : CBool
    fun cmark_node_get_type(node : CmarkNode*) : NodeType
    fun cmark_node_get_type_string(node : CmarkNode*) : LibC::Char*
    fun cmark_node_get_literal(node : CmarkNode*) : LibC::Char*
    fun cmark_node_set_literal(node : CmarkNode*, content : LibC::Char*) : CBool
    fun cmark_node_get_heading_level(node : CmarkNode*) : LibC::Int
    fun cmark_node_set_heading_level(node : CmarkNode*, level : LibC::Int) : CBool
    fun cmark_node_get_list_type(node : CmarkNode*) : ListType
    fun cmark_node_set_list_type(node : CmarkNode*, type : ListType) : CBool
    fun cmark_node_get_list_delim(node : CmarkNode*) : DelimType
    fun cmark_node_set_list_delim(node : CmarkNode*, delim : DelimType) : CBool
    fun cmark_node_get_list_start(node : CmarkNode*) : LibC::Int
    fun cmark_node_set_list_start(node : CmarkNode*, start : LibC::Int) : CBool
    fun cmark_node_get_list_tight(node : CmarkNode*) : CBool
    fun cmark_node_set_list_tight(node : CmarkNode*, tight : CBool) : CBool
    fun cmark_node_get_fence_info(node : CmarkNode*) : LibC::Char*
    fun cmark_node_set_fence_info(node : CmarkNode*, info : LibC::Char*) : CBool
    fun cmark_node_set_fenced(node : CmarkNode*, fenced : LibC::Int, length : LibC::Int, offset : LibC::Int, character : LibC::Char) : CBool
    fun cmark_node_get_fenced(node : CmarkNode*, length : LibC::Int*, offset : LibC::Int*, character : LibC::Char*) : CBool
    fun cmark_node_get_url(node : CmarkNode*) : LibC::Char*
    fun cmark_node_set_url(node : CmarkNode*, url : LibC::Char*) : CBool
    fun cmark_node_get_title(node : CmarkNode*) : LibC::Char*
    fun cmark_node_set_title(node : CmarkNode*, title : LibC::Char*) : CBool
    fun cmark_node_get_on_enter(node : CmarkNode*) : LibC::Char*
    fun cmark_node_set_on_enter(node : CmarkNode*, on_enter : LibC::Char*) : CBool
    fun cmark_node_get_on_exit(node : CmarkNode*) : LibC::Char*
    fun cmark_node_set_on_exit(node : CmarkNode*, on_exit : LibC::Char*) : CBool
    fun cmark_node_get_start_line(node : CmarkNode*) : LibC::Int
    fun cmark_node_get_start_column(node : CmarkNode*) : LibC::Int
    fun cmark_node_get_end_line(node : CmarkNode*) : LibC::Int
    fun cmark_node_get_end_column(node : CmarkNode*) : LibC::Int

    # Tree manipulation

    fun cmark_node_unlink(node : CmarkNode*) : Void
    fun cmark_node_insert_before(node : CmarkNode*, sibling : CmarkNode*) : CBool
    fun cmark_node_insert_after(node : CmarkNode*, sibling : CmarkNode*) : CBool
    fun cmark_node_replace(oldnode : CmarkNode*, newnode : CmarkNode*) : CBool
    fun cmark_node_prepend_child(node : CmarkNode*, child : CmarkNode*) : CBool
    fun cmark_node_append_child(node : CmarkNode*, child : CmarkNode*) : CBool
    fun cmark_consolidate_text_nodes(root : CmarkNode*) : Void
    fun cmark_node_own(root : CmarkNode*) : Void

    # Parsing

    fun cmark_parser_new(options : LibC::Int) : CmarkParser*
    fun cmark_parser_new_with_mem(options : LibC::Int, mem: CmarkMem*) : CmarkParser*
    fun cmark_parser_free(parser: CmarkParser*) : Void
    fun cmark_parser_feed(parser: CmarkParser*, buffer : LibC::Char*, len : LibC::SizeT) : Void
    fun cmark_parser_finish(parser: CmarkParser*) : CmarkNode*
    fun cmark_parse_document(text : LibC::Char*, len : LibC::SizeT, options : LibC::Int) : CmarkNode*
    fun cmark_parse_file(f : FILE*, options : LibC::Int) : CmarkNode*

    # Rendering

    fun cmark_render_xml(root : CmarkNode*, options : LibC::Int) : LibC::Char*
    fun cmark_render_html(root : CmarkNode*, options : LibC::Int, extensions: CmarkLinkedList*) : LibC::Char*
    fun cmark_render_man(root : CmarkNode*, options : LibC::Int, width: LibC::Int) : LibC::Char*
    fun cmark_render_commonmark(root : CmarkNode*, options : LibC::Int, width: LibC::Int) : LibC::Char*
    fun cmark_render_plaintext(root : CmarkNode*, options : LibC::Int, width : LibC::Int) : LibC::Char*
    fun cmark_render_latex(root : CmarkNode*, options : LibC::Int, width: LibC::Int) : LibC::Char*

    # Node containment

    fun cmark_node_can_contain_type(node : CmarkNode*, child_type : NodeType) : CBool

    # Version information

    fun cmark_version() : LibC::Int

    # Extension

    fun cmark_list_syntax_extensions(mem : CmarkMem*) : CmarkLinkedList*
    fun cmark_node_get_syntax_extension(node : CmarkNode*) : CmarkSyntaxExtension*
    fun cmark_node_set_syntax_extension(node : CmarkNode*, extension : CmarkSyntaxExtension*) : CBool

    CMARK_NODE_TYPE_PRESENT = 0x8000
    CMARK_NODE_TYPE_BLOCK   = 0x8000 | 0x0000
    CMARK_NODE_TYPE_INLINE  = 0x8000 | 0x4000
    CMARK_NODE_TYPE_MASK    = 0xc000
    CMARK_NODE_VALUE_MASK   = 0x3fff

    enum NodeType
      # Error status
      CMARK_NODE_NONE = 0x0000

      # Block
      CMARK_NODE_DOCUMENT            = CMARK_NODE_TYPE_BLOCK | 0x0001
      CMARK_NODE_BLOCK_QUOTE         = CMARK_NODE_TYPE_BLOCK | 0x0002
      CMARK_NODE_LIST                = CMARK_NODE_TYPE_BLOCK | 0x0003
      CMARK_NODE_ITEM                = CMARK_NODE_TYPE_BLOCK | 0x0004
      CMARK_NODE_CODE_BLOCK          = CMARK_NODE_TYPE_BLOCK | 0x0005
      CMARK_NODE_HTML_BLOCK          = CMARK_NODE_TYPE_BLOCK | 0x0006
      CMARK_NODE_CUSTOM_BLOCK        = CMARK_NODE_TYPE_BLOCK | 0x0007
      CMARK_NODE_PARAGRAPH           = CMARK_NODE_TYPE_BLOCK | 0x0008
      CMARK_NODE_HEADING             = CMARK_NODE_TYPE_BLOCK | 0x0009
      CMARK_NODE_THEMATIC_BREAK      = CMARK_NODE_TYPE_BLOCK | 0x000a
      CMARK_NODE_FOOTNOTE_DEFINITION = CMARK_NODE_TYPE_BLOCK | 0x000b

      # Inline
      CMARK_NODE_TEXT               = CMARK_NODE_TYPE_INLINE | 0x0001
      CMARK_NODE_SOFTBREAK          = CMARK_NODE_TYPE_INLINE | 0x0002
      CMARK_NODE_LINEBREAK          = CMARK_NODE_TYPE_INLINE | 0x0003
      CMARK_NODE_CODE               = CMARK_NODE_TYPE_INLINE | 0x0004
      CMARK_NODE_HTML_INLINE        = CMARK_NODE_TYPE_INLINE | 0x0005
      CMARK_NODE_CUSTOM_INLINE      = CMARK_NODE_TYPE_INLINE | 0x0006
      CMARK_NODE_EMPH               = CMARK_NODE_TYPE_INLINE | 0x0007
      CMARK_NODE_STRONG             = CMARK_NODE_TYPE_INLINE | 0x0008
      CMARK_NODE_LINK               = CMARK_NODE_TYPE_INLINE | 0x0009
      CMARK_NODE_IMAGE              = CMARK_NODE_TYPE_INLINE | 0x000a
      CMARK_NODE_FOOTNOTE_REFERENCE = CMARK_NODE_TYPE_INLINE | 0x000b
    end

    $cmark_node_table = CMARK_NODE_TABLE : NodeType
    $cmark_node_table_row = CMARK_NODE_TABLE_ROW : NodeType
    $cmark_node_table_cell = CMARK_NODE_TABLE_CELL : NodeType
    $cmark_node_strikethrough = CMARK_NODE_STRIKETHROUGH : NodeType

    enum ListType
      CMARK_NO_LIST
      CMARK_BULLET_LIST
      CMARK_ORDERED_LIST
    end

    enum DelimType
      CMARK_NO_DELIM
      CMARK_PERIOD_DELIM
      CMARK_PAREN_DELIM
    end

    enum EventType
      CMARK_EVENT_NONE
      CMARK_EVENT_DONE
      CMARK_EVENT_ENTER
      CMARK_EVENT_EXIT
    end

    enum Escaping
      LITERAL
      NORMAL
      TITLE
      URL
    end

    struct TableRow
      n_columns : UInt16
      paragraph_offset : LibC::Int
      cells : CmarkLinkedList*
    end

    struct NodeTable
      n_columns : UInt16
      alignments: UInt8*
    end

    struct NodeTableRow
      is_header : CBool
    end

    struct NodeCell
      buf : CmarkStrbuf*
      start_offset : LibC::Int
      end_offset : LibC::Int
      internal_offset : LibC::Int
    end

    type CmarkFreeFunc = ((CmarkMem*, Void*) -> Void)*

    type CmarkOpenBlockFunc = ((CmarkSyntaxExtension*, LibC::Int, CmarkParser*, CmarkNode*, LibC::UChar*, LibC::Int)-> CmarkNode*)*
    type CmarkMatchInlineFunc = ((CmarkSyntaxExtension*, CmarkParser*, CmarkNode*, LibC::UChar, CmarkInlineParser*)-> CmarkNode*)*
    type CmarkInlineFromDelimFunc = ((CmarkSyntaxExtension*, CmarkParser*, CmarkInlineParser*, Delimiter*, Delimiter*)-> Delimiter*)*
    type CmarkMatchBlockFunc = ((CmarkSyntaxExtension*, CmarkParser*, LibC::UChar*, LibC::Int, CmarkNode*) -> LibC::Int)*
    type CmarkGetTypeStringFunc = ((CmarkSyntaxExtension*, CmarkNode*) -> LibC::Char*)*
    type CmarkCanContainFunc = ((CmarkSyntaxExtension*, CmarkNode*, NodeType) -> LibC::Int)*
    type CmarkContainsInlinesFunc = ((CmarkSyntaxExtension*, CmarkNode*) -> LibC::Int)*
    type CmarkCommonRenderFunc = ((CmarkSyntaxExtension*, CmarkRenderer*, CmarkNode*, EventType, LibC::Int) -> Void)*
    type CmarkCommonmarkEscapeFunc = ((CmarkSyntaxExtension*, CmarkNode*, LibC::Int) -> LibC::Int)*
    type CmarkXMLAttrFunc = ((CmarkSyntaxExtension*, CmarkNode*) -> LibC::Char*)*
    type CmarkHTMLRenderFunc = ((CmarkSyntaxExtension*, CmarkHTMLRenderer*, CmarkNode*, EventType, LibC::Int) -> Void)*
    type CmarkHTMLFilterFunc = ((CmarkSyntaxExtension*, LibC::UChar*, LibC::SizeT) -> LibC::Int)*
    type CmarkPostprocessFunc = ((CmarkSyntaxExtension*, CmarkParser*, CmarkNode*) -> CmarkNode*)*
    type CmarkIspunctFunc = ((LibC::Char) -> LibC::Int)*
    type CmarkOpaqueAllocFunc = ((CmarkSyntaxExtension*, CmarkMem*, CmarkNode*) -> Void)*
    type CmarkOpaqueFreeFunc = ((CmarkSyntaxExtension*, CmarkMem*, CmarkNode*) -> Void)*

    type CmarkMapFreeF = ((CmarkMap*, CmarkMapEntry*) -> Void)*


    # == GFM Extensions

    # Syntax extensions

    fun cmark_gfm_core_extensions_ensure_registered() : Void
    fun cmark_find_syntax_extension(name : LibC::Char*) : CmarkSyntaxExtension*
    fun cmark_parser_attach_syntax_extension(parser: CmarkParser*, extension: CmarkSyntaxExtension*): CBool

    # Node accessors

    fun cmark_node_get_string_content(node: CmarkNode*) : LibC::Char*
    fun cmark_node_set_string_content(node: CmarkNode*, content: LibC::Char*) : CBool

    # Extension accessors

    fun cmark_gfm_extensions_get_table_columns(node: CmarkNode*) : UInt16
    fun cmark_gfm_extensions_set_table_columns(node: CmarkNode*, n_columns : UInt16) : CBool
    fun cmark_gfm_extensions_get_table_alignments(node: CmarkNode*) : UInt8*
    fun cmark_gfm_extensions_set_table_alignments(node: CmarkNode*, ncols : UInt16, alignments : UInt8*) : CBool
    fun cmark_gfm_extensions_get_table_row_is_header(node: CmarkNode*) : CBool
    fun cmark_gfm_extensions_set_table_row_is_header(node: CmarkNode*, is_header : CBool) : CBool
    fun cmark_gfm_extensions_get_tasklist_item_checked(node: CmarkNode*) : CBool
    fun cmark_gfm_extensions_set_tasklist_item_checked(node: CmarkNode*, is_checked : CBool) : CBool
  end

end
