module Cmark
  @[Flags]
  # A flag enum to enable GFM extensions for node parsing and rendering.
  #
  # You can easily combine options like this:
  # ```
  # extensions = Extension.flags(Table, Autolink)
  # ```
  enum Extension
    Table
    Strikethrough
    Autolink
    Tagfilter
    Tasklist
  end
end