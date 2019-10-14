module Cmark
  # A text alignment value for columns of nodes with `NodeType::Table`.
  enum Alignment : UInt8
    # C library value '\0'
    None    = 0x00
    # C library value 'l'
    Left    = 0x6C
    # C library value 'c'
    Center  = 0x63
    # C library value 'r'
    Right   = 0x72
  end
end