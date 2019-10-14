require "./lib_cmark"

module Cmark
  # A delimiter type for lists with `ListType::Ordered`.
  enum DelimType
    # No specific delimiter (i.e., node is not an ordered list)
    None    = LibCmark::DelimType::CMARK_NO_DELIM
    # Period delimiter, such as `7.`
    Period  = LibCmark::DelimType::CMARK_PERIOD_DELIM
    # Parenthesis delimiter, such as `7)`
    Paren   = LibCmark::DelimType::CMARK_PAREN_DELIM
  end
end