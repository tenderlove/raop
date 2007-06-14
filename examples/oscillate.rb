require 'raop'

raop = Net::RAOP::Client.new('192.168.1.173')
raop.connect

th = Thread.new(raop) { |cl|
  cl.play $stdin
}

while th.alive?
  30.downto(0) { |i|
    puts i
    raop.volume = i
  }
  0.upto(30) { |i|
    puts i
    raop.volume = i
  }
end


raop.disconnect

