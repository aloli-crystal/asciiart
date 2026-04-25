require "./spec_helper"

# These specs exercise the parser against the real embedded fonts —
# easier and more realistic than hand-crafting a 95-glyph fixture.

describe AsciiArt::FlfFont do
  describe ".parse" do
    it "reads the header fields of the standard font" do
      font = AsciiArt::Fonts.load("standard")
      font.hardblank.should eq('$')
      font.height.should be > 0
      font.baseline.should be > 0
      font.max_length.should be > 0
      font.print_direction.should eq(0)
    end

    it "captures the comment block" do
      AsciiArt::Fonts.load("standard").comment.should contain("Standard")
    end

    it "decodes printable ASCII glyphs" do
      font = AsciiArt::Fonts.load("standard")
      # Every printable ASCII character must have a glyph.
      (32..126).each do |codepoint|
        font.glyph_for(codepoint.chr).should_not be_nil
      end
    end

    it "produces glyphs of consistent height" do
      font = AsciiArt::Fonts.load("standard")
      glyph = font.glyph_for('A').not_nil!
      glyph.size.should eq(font.height)
    end

    it "produces rectangular glyphs (every line of the same width)" do
      font = AsciiArt::Fonts.load("standard")
      glyph = font.glyph_for('M').not_nil!
      widths = glyph.map(&.size).uniq
      widths.size.should eq(1)
    end

    it "raises on an empty string" do
      expect_raises(ArgumentError, /empty FIGfont/) do
        AsciiArt::FlfFont.parse("")
      end
    end

    it "raises when the header signature is wrong" do
      bad = "xxxxx 2 2 4 0 0\n"
      expect_raises(ArgumentError, /must start with 'flf2a'/) do
        AsciiArt::FlfFont.parse(bad)
      end
    end

    it "raises when the file is truncated mid-glyph" do
      truncated = AsciiArt::Fonts::FONT_SOURCES["standard"].lines.first(20).join('\n')
      expect_raises(ArgumentError) do
        AsciiArt::FlfFont.parse(truncated)
      end
    end
  end

  describe "#soften_hardblanks" do
    it "replaces every hardblank with a real space" do
      font = AsciiArt::Fonts.load("standard")
      # standard.flf uses `$` as the hardblank.
      font.soften_hardblanks("a$$b").should eq("a  b")
    end

    it "leaves non-hardblank characters untouched" do
      font = AsciiArt::Fonts.load("standard")
      font.soften_hardblanks("plain text").should eq("plain text")
    end
  end

  describe "#glyph_for" do
    it "returns nil for a codepoint absent from the font" do
      font = AsciiArt::Fonts.load("standard")
      # U+1F600 (😀) is well outside Latin-1 — no FIGfont covers it.
      font.glyph_for('\u{1F600}').should be_nil
    end
  end
end
