require "./spec_helper"

describe AsciiArt do
  describe ".render" do
    it "uses the standard font by default" do
      AsciiArt.render("X").should eq(AsciiArt.render("X", font: "standard"))
    end

    it "produces different output for different fonts" do
      AsciiArt.render("X", font: "small").should_not eq(AsciiArt.render("X", font: "big"))
    end
  end

  describe ".fonts" do
    it "returns the list of built-in fonts" do
      fonts = AsciiArt.fonts
      fonts.should contain("standard")
      fonts.should contain("small")
      fonts.should contain("big")
      fonts.should contain("slant")
      fonts.should contain("banner")
    end

    it "is sorted alphabetically (predictable for `--list-fonts`)" do
      AsciiArt.fonts.should eq(AsciiArt.fonts.sort)
    end
  end
end

describe AsciiArt::Fonts do
  describe ".load" do
    it "loads every built-in font without raising" do
      AsciiArt::Fonts.available.each do |name|
        font = AsciiArt::Fonts.load(name)
        font.height.should be > 0
      end
    end

    it "caches the parsed font (same instance on repeat calls)" do
      a = AsciiArt::Fonts.load("standard")
      b = AsciiArt::Fonts.load("standard")
      a.should be(b) # `be` checks object identity
    end

    it "raises KeyError on an unknown font name" do
      expect_raises(KeyError, /unknown built-in font/) do
        AsciiArt::Fonts.load("nonexistent-font")
      end
    end
  end
end
