require 'test/unit'
require 'raop'

class RAOPTest < Test::Unit::TestCase
  def setup
    @raop = Net::RAOP::Client.new('192.168.1.173')
  end

  def test_raop_connect
    #@raop.connect
    #File.open('test/data/o.raw') { |file|
    #  @raop.play file
    #}
  end
end
