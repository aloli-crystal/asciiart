require "option_parser"
require "./ascii_art"

# asciiart CLI.
#
# ```
# # Default font.
# asciiart "Hello"
#
# # Pick another built-in font.
# asciiart -f slant "Crystal"
#
# # Use your own .flf file.
# asciiart --font-file ./mycustom.flf "Hi"
#
# # List available built-in fonts.
# asciiart --list-fonts
# ```

font_name = AsciiArt::DEFAULT_FONT
font_file : String? = nil

parser = OptionParser.new do |p|
  p.banner = "Usage : asciiart [options] TEXTE..."
  p.separator ""
  p.separator "Options :"

  p.on("-f NAME", "--font NAME", "Built-in font (default: #{AsciiArt::DEFAULT_FONT})") { |v| font_name = v }
  p.on("--font-file PATH", "Use a custom .flf font file") { |v| font_file = v }
  p.on("-l", "--list-fonts", "List built-in fonts and exit") do
    AsciiArt.fonts.each { |name| puts name }
    exit 0
  end
  p.on("-v", "--version", "Show version and exit") do
    puts "asciiart #{AsciiArt::VERSION}"
    exit 0
  end
  p.on("-h", "--help", "Show this help and exit") do
    puts p
    exit 0
  end

  p.invalid_option do |flag|
    STDERR.puts "Option inconnue : #{flag}"
    STDERR.puts p
    exit 1
  end
end

# Collect positional arguments (the text to render). OptionParser
# in Crystal does not return them from `parse`, so we capture via
# `unknown_args`.
positional = [] of String
parser.unknown_args { |args| positional = args }
parser.parse(ARGV)

if positional.empty?
  STDERR.puts "Erreur : aucun texte spécifié"
  STDERR.puts parser
  exit 1
end

# All non-option arguments are joined with a single space — lets the
# user write `asciiart Hello World` without quoting.
text = positional.join(' ')

begin
  font = if path = font_file
           AsciiArt::Fonts.load_file(path)
         else
           AsciiArt::Fonts.load(font_name)
         end
  puts AsciiArt::Renderer.new(font).render(text)
rescue ex : KeyError
  STDERR.puts "Erreur : #{ex.message}"
  exit 1
rescue ex : ArgumentError
  STDERR.puts "Erreur : #{ex.message}"
  exit 1
rescue ex : File::NotFoundError
  STDERR.puts "Erreur : #{ex.message}"
  exit 1
end
