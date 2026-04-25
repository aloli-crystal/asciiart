require "./spec_helper"

describe AsciiArt::Renderer do
  describe "#render" do
    it "returns a multi-line string with `\\n` separators" do
      result = AsciiArt::Renderer.new(AsciiArt::Fonts.load("standard")).render("Hi")
      result.should be_a(String)
      result.lines.size.should be > 1
    end

    it "produces output that matches the font height" do
      font = AsciiArt::Fonts.load("standard")
      lines = AsciiArt::Renderer.new(font).render_lines("Hi")
      lines.size.should eq(font.height)
    end

    it "preserves the input characters' visible identity" do
      # Render the letter `H` and check that the rendered glyph
      # contains the letter `H`'s pipe characters in its first
      # column (a stable property of the standard font).
      lines = AsciiArt::Renderer.new(AsciiArt::Fonts.load("standard")).render_lines("H")
      lines.any?(&.includes?("|")).should be_true
    end

    it "renders unknown characters as a blank gap (no crash)" do
      font = AsciiArt::Fonts.load("standard")
      # U+1F600 (😀) — almost certainly absent from a Latin FIGfont.
      result = AsciiArt::Renderer.new(font).render("\u{1F600}")
      result.should be_a(String)
      result.lines.size.should eq(font.height)
    end

    it "renders an empty string as `height` empty lines" do
      font = AsciiArt::Fonts.load("standard")
      lines = AsciiArt::Renderer.new(font).render_lines("")
      lines.size.should eq(font.height)
      lines.each(&.should(eq("")))
    end
  end

  describe "#width" do
    it "returns a strictly positive width for a non-empty string" do
      AsciiArt::Renderer.new(AsciiArt::Fonts.load("standard")).width("X").should be > 0
    end

    it "returns 0 for an empty string" do
      AsciiArt::Renderer.new(AsciiArt::Fonts.load("standard")).width("").should eq(0)
    end
  end
end
