module AsciiArt
  # Renders a string into a multi-line ASCII art banner using a
  # `FlfFont`. v0.1 implements the simplest layout — full-width
  # juxtaposition with no smushing, no kerning. This always produces
  # a readable result; the only cost is a slightly wider banner than
  # what `figlet` itself would produce in default mode.
  #
  # Smushing (the FIGlet algorithm that overlaps adjacent glyphs to
  # tighten letter spacing) is documented for v0.2.
  class Renderer
    @font : FlfFont

    def initialize(@font : FlfFont)
    end

    # Renders `text` and returns it as a single string with `\n`
    # between lines, ready to print. Unknown characters fall back to
    # a blank glyph (so they leave a gap rather than crash).
    def render(text : String) : String
      render_lines(text).join('\n')
    end

    # Renders `text` and returns the array of lines (one entry per
    # row of the banner). Useful for callers that want to colourise
    # the output, frame it, or measure its bounding box.
    def render_lines(text : String) : Array(String)
      height = @font.height
      rows = Array.new(height) { String::Builder.new }

      text.each_char do |char|
        glyph = @font.glyph_for(char) || blank_glyph(height)
        glyph.each_with_index do |line, i|
          rows[i] << line
        end
      end

      # Replace hardblanks by real spaces only at the very end —
      # if we did it earlier, we couldn't tell intentional blanks
      # from glyph padding (matters once smushing arrives in v0.2).
      rows.map { |b| @font.soften_hardblanks(b.to_s) }
    end

    # Returns the width of the rendered banner in characters,
    # without actually rendering. Cheap to call repeatedly.
    def width(text : String) : Int32
      total = 0
      text.each_char do |char|
        glyph = @font.glyph_for(char) || blank_glyph(@font.height)
        total += glyph.first?.try(&.size) || 0
      end
      total
    end

    # Builds a fallback blank glyph for unknown codepoints — same
    # height as the font, fixed width of 4 spaces (visually obvious
    # gap, doesn't disappear silently).
    private def blank_glyph(height : Int32) : Array(String)
      Array.new(height, "    ")
    end
  end
end
