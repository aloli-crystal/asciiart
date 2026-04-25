module AsciiArt
  # Parsed representation of a FIGlet font (.flf file).
  #
  # The .flf format (FIGfont version 2) is a plain-text container
  # specifying a header line, a multi-line comment, and one block of
  # `height` lines per glyph. Glyphs are stored in this fixed order:
  #
  #   1. printable ASCII 32..126 (95 glyphs, in code-point order)
  #   2. seven Latin-1 extras (U+00C4 Ä, U+00D6 Ö, U+00DC Ü, U+00E4 ä,
  #      U+00F6 ö, U+00FC ü, U+00DF ß) — required by spec
  #   3. zero or more "code-tagged" glyphs prefixed by their codepoint
  #
  # Each glyph line ends with a "endmark" character (typically `@`)
  # which is repeated twice on the last line. The "hardblank" character
  # declared in the header (often `$`) is rendered as an actual space
  # at draw time but stops adjacent glyphs from being smushed together.
  #
  # This v0.1 parser supports the printable ASCII range; Latin-1
  # extras are read but optional, code-tagged glyphs are skipped (used
  # only by exotic fonts for non-Latin scripts).
  class FlfFont
    # Character used to pad short lines inside a glyph; rendered as
    # a real space at draw time. Distinct from a regular space so the
    # font can encode "intentional blank columns" inside a glyph.
    getter hardblank : Char
    # Vertical size of every glyph, in lines.
    getter height : Int32
    # Distance from the top of the glyph to the baseline (the line
    # most letters sit on). Exposed for callers that want to align
    # multiple fonts vertically.
    getter baseline : Int32
    # Maximum width of any line in the font.
    getter max_length : Int32
    # Direction: 0 = left-to-right (default), 1 = right-to-left.
    # Right-to-left fonts mirror the layout but are not yet rendered
    # specially in v0.1 (we just emit them in source order).
    getter print_direction : Int32
    # Comment block from the .flf header, joined by "\n". Useful for
    # `--show-credits` style output.
    getter comment : String
    # Map from codepoint to glyph (each glyph = `height` strings of
    # equal width). Built lazily during parsing.
    getter glyphs : Hash(Int32, Array(String))

    def initialize(@hardblank : Char,
                   @height : Int32,
                   @baseline : Int32,
                   @max_length : Int32,
                   @print_direction : Int32,
                   @comment : String,
                   @glyphs : Hash(Int32, Array(String)))
    end

    # Parses the content of a .flf file and returns a `FlfFont`.
    # Raises `ArgumentError` on malformed input rather than silently
    # returning a half-initialised font.
    def self.parse(content : String) : FlfFont
      raise ArgumentError.new("empty FIGfont") if content.empty?
      lines = content.split('\n')

      header = parse_header(lines[0])

      # Skip the comment block — `comment_lines` lines after the header.
      comment_lines_count = header[:comment_lines]
      raise ArgumentError.new("truncated FIGfont (header announces #{comment_lines_count} comment lines, file has only #{lines.size - 1})") if lines.size < 1 + comment_lines_count
      comment = lines[1, comment_lines_count].join('\n')

      # Glyph data starts right after the comment block.
      cursor = 1 + comment_lines_count
      glyphs = {} of Int32 => Array(String)

      # 1. Printable ASCII 32..126 in code-point order.
      (32..126).each do |codepoint|
        glyph, cursor = read_glyph(lines, cursor, header[:height])
        glyphs[codepoint] = glyph
      end

      # 2. Seven Latin-1 required glyphs (some fonts have them, others
      #    don't ; if we run out of lines, we stop without raising).
      required_extras = [0x00C4, 0x00D6, 0x00DC, 0x00E4, 0x00F6, 0x00FC, 0x00DF]
      required_extras.each do |codepoint|
        break if cursor + header[:height] > lines.size
        glyph, cursor = read_glyph(lines, cursor, header[:height])
        glyphs[codepoint] = glyph
      end

      # 3. Code-tagged glyphs (skipped in v0.1 — rare for Latin text).

      new(
        hardblank: header[:hardblank],
        height: header[:height],
        baseline: header[:baseline],
        max_length: header[:max_length],
        print_direction: header[:print_direction],
        comment: comment,
        glyphs: glyphs,
      )
    end

    # Convenience: reads the .flf from `path` and parses it.
    def self.load(path : String) : FlfFont
      parse(File.read(path))
    end

    # Returns the glyph for `char`, or `nil` when the font has no
    # rendering for that character. Callers typically substitute a
    # blank glyph (or a `?`) when a character is missing.
    def glyph_for(char : Char) : Array(String)?
      @glyphs[char.ord]?
    end

    # Replace every hardblank in `line` by a literal space — meant to
    # be applied just before printing, never on the raw glyph data
    # (otherwise smushing would lose its anchor).
    def soften_hardblanks(line : String) : String
      line.gsub(@hardblank, ' ')
    end

    # Parses the first line of a .flf file. The header is a sequence
    # of whitespace-separated tokens; only the first six are mandatory
    # in the original 1993 spec. The remaining three are FIGfont 2
    # extensions used for advanced smushing — we ignore the smushing
    # parameters in v0.1 (no kerning) but read them off the header
    # for completeness.
    private def self.parse_header(line : String) : NamedTuple(
      hardblank: Char,
      height: Int32,
      baseline: Int32,
      max_length: Int32,
      old_layout: Int32,
      comment_lines: Int32,
      print_direction: Int32,
      full_layout: Int32,
      codetag_count: Int32,
    )
      tokens = line.split
      raise ArgumentError.new("FIGfont header must have at least 6 tokens, got #{tokens.size}") if tokens.size < 6

      signature_with_hardblank = tokens[0]
      raise ArgumentError.new("FIGfont signature must start with 'flf2a', got #{signature_with_hardblank.inspect}") unless signature_with_hardblank.starts_with?("flf2a")
      hardblank = signature_with_hardblank[5]?
      raise ArgumentError.new("FIGfont signature must include a hardblank character") unless hardblank

      {
        hardblank:       hardblank,
        height:          tokens[1].to_i,
        baseline:        tokens[2].to_i,
        max_length:      tokens[3].to_i,
        old_layout:      tokens[4].to_i,
        comment_lines:   tokens[5].to_i,
        print_direction: tokens[6]?.try(&.to_i) || 0,
        full_layout:     tokens[7]?.try(&.to_i) || -1,
        codetag_count:   tokens[8]?.try(&.to_i) || 0,
      }
    end

    # Reads `height` lines starting at `cursor` and returns the glyph
    # plus the cursor advanced past it.
    #
    # Each glyph line ends with one or two copies of the line's last
    # character (the "endmark"). On the final line the endmark appears
    # twice. We strip the endmarks, then pad short lines with spaces
    # so all lines of a glyph have the same width — required by the
    # renderer to juxtapose glyphs cleanly.
    private def self.read_glyph(lines : Array(String),
                                cursor : Int32,
                                height : Int32) : Tuple(Array(String), Int32)
      raw = lines[cursor, height]
      raise ArgumentError.new("truncated FIGfont glyph at line #{cursor}") if raw.size < height

      stripped = raw.map_with_index do |line, i|
        endmark = line[-1]?
        # Strip 2 endmarks on the last line, 1 on the others.
        n = (i == height - 1 ? 2 : 1)
        n.times { line = line[0, line.size - 1] if line.ends_with?(endmark.to_s) }
        line
      end

      # Pad to the widest line so the glyph is rectangular.
      width = stripped.max_of(&.size)
      glyph = stripped.map(&.ljust(width))

      {glyph, cursor + height}
    end
  end
end
