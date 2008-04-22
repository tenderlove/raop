require 'openssl'
require 'socket'

class Net::RAOP::Client
  ##
  # The version of Net::RAOP::Client you're using
  VERSION = '0.1.1'

  class Server
    attr_accessor :host, :aes_crypt, :rtsp_client, :session_id, :data_socket
    def initialize(host, aes_crypt = aes_cipher)
      @host         = host
      @aes_crypt    = aes_crypt
      @rtsp_client  = nil
      @session_id   = nil
      @data_socket  = nil
    end
  end

  ##
  # Create a new Net::RAOP::Client to connect to +host+ Airport Express
  def initialize(*host)
    @aes_crypt = aes_cipher
    @clients = host.map { |hostname|
      Server.new(hostname, @aes_crypt)
    }
  end

  ##
  # Connect to the Airport Express
  def connect
    random_data = Array.new(28) { |x| rand(0xFF) }.pack('C*')

    sid = sprintf('%0#10d', random_data.slice!(0, 4).unpack('L').first)
    sci = sprintf('%0#18X', random_data.slice!(0, 8).unpack('Q').first)\
      .slice(2..-1)
    sac = [random_data].pack('m')

    key = [rsa_encrypt(@aes_key)].pack('m')
    iv  = [@aes_iv].pack('m')

    @clients.each do |client|
      client.rtsp_client = Net::RTSP.new(client.host, sid, sci)

      announce = Net::RTSP::Announce.new(sac, key, iv)
      response = client.rtsp_client.request(announce)

      # FIXME Check for audio cable hookup

      response = client.rtsp_client.request(Net::RTSP::Setup.new)
      transport_info = {}
      response['transport'].split(';').each do |token|
        k, v = token.split('=', 2)
        transport_info[k] = v
      end
      client.data_socket = TCPSocket.open(client.host,
                                          transport_info['server_port'])
      client.session_id = response['session']

      response = client.rtsp_client.request(Net::RTSP::Record.new(client.session_id))
      params = Net::RTSP::SetParameter.new(client.session_id,
                                           { :volume => -30 }
                                          )
      response = client.rtsp_client.request(params)
    end
  end

  ##
  # Set the +volume+ on the Airport Express. -144 is quiet, 0 is loud.
  def volume=(volume, client_index = :all)
    volume = volume.abs
    raise ArgumentError if volume > 144

    if client_index == :all
      @clients.each { |client|
        params = Net::RTSP::SetParameter.new(client.session_id,
                                             { :volume => "-#{volume}".to_i }
                                            )
        response = client.rtsp_client.request(params)
      }
    else
      client = @clients[client_index]
      params = Net::RTSP::SetParameter.new(client.session_id,
                                           { :volume => "-#{volume}".to_i }
                                          )
      response = client.rtsp_client.request(params)
    end
  end

  ##
  # Stream +file+ to the Airport Express
  def play(file)
    while data = file.read(4096 * 2 * 2)
      send_sample(self.class.encode_alac(data))
    end
  end

  ##
  # Disconnect from the Airport Express
  def disconnect
    @clients.each { |client|
      client.rtsp_client.request(Net::RTSP::Teardown.new)
    }
  end

  private
  def flush
    puts @seq
    @rtsp_client.request(Net::RTSP::Flush.new(@session_id, @seq))
  end

  def options
    @clients.each { |client|
      client.rtsp_client.request(Net::RTSP::Options.new)
    }
  end

  @@data_cache = {}
  def send_sample(sample, pos = 0, count = sample.length)
    # FIXME do we really need +pos+ or +count+?
    
    crypt_length = sample.length / 16 * 16

    unless header = @@data_cache[count]
      header = [
        0x24, 0x00, 0x00, 0x00,
        0xF0, 0xFF, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
      ]
      ab = [count + 12].pack('n').unpack('C*')
      ab.each_with_index { |x, i| header[i + 2] = x }
      @@data_cache[count] = header.pack('C*')
      header = @@data_cache[count]
    end

    @aes_crypt.reset
    data = header +
    # Encryption section
      @aes_crypt.update(sample.slice(0, crypt_length)) +
      sample.slice(crypt_length, sample.length)

    @clients.each { |client|
      client.data_socket.write(data)
    }
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

  HEADER = [32, 0, 2].pack('C3')
end
