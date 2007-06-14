require 'raop'

# usage:
# lame --decode --quite some_file.mp3 | ruby read_stream.rb 192.168.1.173
#

raop = Net::RAOP::Client.new(ARGV[0])
raop.connect
raop.play $stdin
raop.disconnect

