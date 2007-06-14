require 'raop'

raop = Net::RAOP::Client.new('192.168.1.173')
raop.connect
raop.play $stdin
raop.disconnect

