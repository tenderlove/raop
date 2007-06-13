require 'test/unit'
require 'raop'

class ALACTest < Test::Unit::TestCase
  def setup
    File.open('test/data/frame.txt', 'rb') { |file|
      @input_frame = file.readline.chomp.unpack('m').first
    }
    File.open('test/data/out_frame.txt', 'rb') { |file|
      @output_frame = file.readline.chomp.unpack('m').first
    }
  end

  def test_encode_alac
    output_frame = Net::RAOP::Client.encode_alac(@input_frame)
    assert_equal(@output_frame, output_frame)
  end
end
