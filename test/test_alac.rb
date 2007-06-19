require 'test/unit'
require 'raop'

class ALACTest < Test::Unit::TestCase
  def setup
    File.open('test/data/frame.b64', 'rb') { |file|
      @input_frame = file.readline.chomp.unpack('m').first
    }
    File.open('test/data/out_frame.b64', 'rb') { |file|
      @output_frame = file.readline.chomp.unpack('m').first
    }
  end

  def test_decode_alac
    input_frame = Net::RAOP::Client.decode_alac(@output_frame)
    assert_equal(@input_frame.length, input_frame.length)
    assert_equal(@input_frame, input_frame)
  end

  def test_encode_alac
    output_frame = Net::RAOP::Client.encode_alac(@input_frame)
    assert_equal(@output_frame, output_frame)
  end
end
