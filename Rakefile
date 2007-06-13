require 'hoe'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require 'raop'

Hoe.new('raop-client', Net::RAOP::Client::VERSION) do |p|
  p.rubyforge_name  = 'raop'
  p.author          = 'Aaron Patterson'
  p.email           = 'aaronp@rubyforge.org'
  p.summary         = "Airport Express streaming music client"
  p.description     = p.paragraphs_of('README.txt', 3).join("\n\n")
  p.url             = p.paragraphs_of('README.txt', 1).first.strip
  p.changes         = p.paragraphs_of('CHANGELOG.txt', 0..2).join("\n\n")
end


