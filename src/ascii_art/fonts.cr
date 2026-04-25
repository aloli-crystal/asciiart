module AsciiArt
  # Built-in FIGlet fonts, embedded as raw .flf source at compile
  # time via the `read_file` macro. Each font is parsed lazily on
  # first use (parsing takes a few ms — no point doing it at startup
  # if the caller only ever uses one).
  #
  # Fonts shipped in v0.1 (all under FIGlet's permissive licence,
  # cf. data/fonts/<name>.flf header comments):
  #
  # * `standard` — the original FIGlet default, ~6 lines tall.
  # * `small`    — compact 4-line version of standard.
  # * `big`      — large, fat letters.
  # * `slant`    — italic-style.
  # * `banner`   — single-line banner using `#` characters.
  module Fonts
    FONT_SOURCES = {
      "standard" => {{ read_file(__DIR__ + "/../../data/fonts/standard.flf") }},
      "small"    => {{ read_file(__DIR__ + "/../../data/fonts/small.flf") }},
      "big"      => {{ read_file(__DIR__ + "/../../data/fonts/big.flf") }},
      "slant"    => {{ read_file(__DIR__ + "/../../data/fonts/slant.flf") }},
      "banner"   => {{ read_file(__DIR__ + "/../../data/fonts/banner.flf") }},
    }

    # Parsed font cache, keyed by font name. Filled on demand.
    @@cache : Hash(String, FlfFont) = {} of String => FlfFont

    # Returns the parsed `FlfFont` for the given built-in name.
    # Raises `KeyError` if the name is unknown — call `available`
    # to discover the valid names first.
    def self.load(name : String) : FlfFont
      @@cache[name] ||= begin
        source = FONT_SOURCES[name]? || raise KeyError.new("unknown built-in font: #{name.inspect}. Available: #{available.join(", ")}")
        FlfFont.parse(source)
      end
    end

    # Lists the names of every built-in font.
    def self.available : Array(String)
      FONT_SOURCES.keys.to_a.sort
    end

    # Loads an external .flf font from `path`, bypassing the
    # built-in registry. Useful when the caller has their own
    # collection of FIGlet fonts.
    def self.load_file(path : String) : FlfFont
      FlfFont.load(path)
    end
  end
end
