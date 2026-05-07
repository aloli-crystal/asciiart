require "./ascii_art/version"
require "./ascii_art/flf_font"
require "./ascii_art/renderer"
require "./ascii_art/fonts"

# AsciiArt — pure-Crystal ASCII art generation.
#
# v0.1 ships a FIGlet-style text-to-banner renderer with five
# embedded fonts (no external runtime dependency).
#
# ```
# require "asciiart"
#
# # One-liner: render text with the default `standard` font.
# puts AsciiArt.render("Hello")
#
# # Choose a built-in font.
# puts AsciiArt.render("Hello", font: "slant")
#
# # Discover what's available.
# AsciiArt.fonts # => ["banner", "big", "slant", "small", "standard"]
#
# # Load your own font from disk.
# font = AsciiArt::Fonts.load_file("./mycustom.flf")
# puts AsciiArt::Renderer.new(font).render("Hi")
# ```
module AsciiArt
  # Default font used by `render` when no `font` argument is given.
  DEFAULT_FONT = "standard"

  # Renders `text` as ASCII art using the named built-in font.
  # Returns the multi-line banner as a single string with `\n`
  # between rows. Convenience wrapper around `Renderer#render`.
  def self.render(text : String, font : String = DEFAULT_FONT) : String
    Renderer.new(Fonts.load(font)).render(text)
  end

  # Same as `render` but returns one entry per row of the banner.
  # Useful when the caller wants to colourise each row, frame the
  # output, or measure the bounding box.
  def self.render_lines(text : String, font : String = DEFAULT_FONT) : Array(String)
    Renderer.new(Fonts.load(font)).render_lines(text)
  end

  # Lists the names of every built-in font.
  def self.fonts : Array(String)
    Fonts.available
  end
end
