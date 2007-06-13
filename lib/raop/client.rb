require 'openssl'
require 'socket'

class Net::RAOP::Client
  ##
  # The version of Net::RAOP::Client you're using
  VERSION = '0.1.0'

  def initialize(host)
    @host         = host
    @aes_crypt    = aes_cipher
    @rtsp_client  = nil
    @session_id   = nil
    @data_socket  = nil
  end

  def connect
    random_data = Array.new(28) { |x| rand(0xFF) }.pack('C*')

    sid = sprintf('%0#10d', random_data.slice!(0, 4).unpack('L').first)
    sci = sprintf('%0#18X', random_data.slice!(0, 8).unpack('Q').first)\
      .slice(2..-1)
    sac = [random_data].pack('m')

    key = [rsa_encrypt(@aes_key)].pack('m')
    iv  = [@aes_iv].pack('m')

    @rtsp_client = Net::RTSP.new(@host, sid, sci)

    announce = Net::RTSP::Announce.new(sac, key, iv)
    response = @rtsp_client.request(announce)

    # FIXME Check for audio cable hookup

    response = @rtsp_client.request(Net::RTSP::Setup.new)
    transport_info = {}
    response['transport'].split(';').each do |token|
      k, v = token.split('=', 2)
      transport_info[k] = v
    end
    @data_socket = TCPSocket.open(@host, transport_info['server_port'])
    @session_id = response['session']

    response = @rtsp_client.request(Net::RTSP::Record.new(@session_id))
    params = Net::RTSP::SetParameter.new(@session_id,
                                         { :volume => -30 }
                                        )
    response = @rtsp_client.request(params)
  end

  def play(file)
    while data = file.read(4096 * 2 * 2)
      send_sample self.class.encode_alac(data)
    end
  end

  def disconnect
    @rtsp_client.request(Net::RTSP::Teardown.new)
  end

  private
  def send_sample(sample, pos = 0, count = sample.length)
    # FIXME do we really need +pos+ or +count+?
    
    crypt_length = sample.length / 16 * 16

    @aes_crypt.reset
    data = [
      0x24, 0x00, 0x00, 0x00,
      0xF0, 0xFF, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
    ] +
    # Encryption section
      @aes_crypt.update(sample.slice(0, crypt_length)).unpack('C*') +
      sample.slice(crypt_length, sample.length).unpack('C*')

    ab = [count + 12].pack('n').unpack('C*')
    ab.each_with_index { |x, i| data[i + 2] = x }
    @data_socket.write(data.pack('C*'))
  end

  def rsa_encrypt(plain_text)
    n = 
      "59dE8qLieItsH1WgjrcFRKj6eUWqi+bGLOX1HL3U3GhC/j0Qg90u3sG/1CUtwC" +
      "5vOYvfDmFI6oSFXi5ELabWJmT2dKHzBJKa3k9ok+8t9ucRqMd6DZHJ2YCCLlDR" +
      "KSKv6kDqnw4UwPdpOMXziC/AMj3Z/lUVX1G7WSHCAWKf1zNS1eLvqr+boEjXuB" +
      "OitnZ/bDzPHrTOZz0Dew0uowxf/+sG+NCK3eQJVxqcaJ/vEHKIVd2M+5qL71yJ" +
      "Q+87X6oV3eaYvt3zWZYD6z5vYTcrtij2VZ9Zmni/UAaHqn9JdsBWLUEpVviYnh" +
      "imNVvYFZeCXg/IdTQ+x4IRdiXNv5hEew=="
    e = "AQAB"

    pkey = OpenSSL::PKey::RSA.new()
    pkey.e = OpenSSL::BN.new(e.unpack('m').first, 2)
    pkey.n = OpenSSL::BN.new(n.unpack('m').first, 2)
    return pkey.public_encrypt(plain_text, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
  end

  def aes_cipher
    aes_crypt = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
    aes_crypt.encrypt
    aes_crypt.key = @aes_key = aes_crypt.random_key
    aes_crypt.iv  = @aes_iv  = aes_crypt.random_iv
    aes_crypt
  end

  class << self
    def encode_alac(bits)
      bits = bits.unpack('C*')
      new_bits = Net::RAOP::BitBuffer.new(bits.length + 3) { |x| 0 }
      new_bits.write_bits(1, 3)
      new_bits.write_bits(0, 4)
      new_bits.write_bits(0, 12)
      new_bits.write_bits(0, 1)
      new_bits.write_bits(0, 2)
      new_bits.write_bits(1, 1)
      0.step(bits.length - 1, 2) do |i|
        new_bits.write_bits(bits[i + 1], 8)
        new_bits.write_bits(bits[i], 8)
      end
      new_bits.pack('C*')
    end
  end
end
