require "./lib_cmark"

module Cmark
  # A type of list for nodes with `NodeType::List`.
  enum ListType
    None    = LibCmark::ListType::CMARK_NO_LIST
    Bullet  = LibCmark::ListType::CMARK_BULLET_LIST
    Ordered = LibCmark::ListType::CMARK_ORDERED_LIST
  end
end