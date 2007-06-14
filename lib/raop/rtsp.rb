require 'net/protocol'
require 'net/http'

module Net
  class RTSP < Protocol
    class << self
      def default_port
        5000
      end
    end

    attr_accessor :debug_output
    attr_reader :port
    attr_reader :address

    def initialize(address, id, instance, port = RTSP.default_port)
      @address          = address
      @port             = port
      @started          = false
      @debug_output     = nil
      @cseq             = 0
      @open_timeout     = nil
      @socket           = nil
      @client_id        = id
      @client_instance  = instance
    end

    def request(req)
      unless started?
        start {
          return request(req)
        }
      end
      req['Client-Instance'] = @client_instance
      begin_transport(req)
      res = transport_request(req)
      end_transport(req, res)
      res
    end

    def start
      raise IOError, 'RTSP session already open' if @started
      if block_given?
        begin
          do_start
          return yield(self)
        ensure
          do_finish
        end
      end
      do_start
      self
    end

    def started?; @started; end

    def connect
      s = timeout(@open_timeout) { TCPSocket.open(address(), port())}
      @socket = BufferedIO.new(s)
    end

    private
    def transport_request(req)
      req.exec(@socket, @client_id, @cseq += 1)
      RTSPResponse.read_new(@socket)
    end

    def begin_transport(req)
    end

    def end_transport(req, res)
      @socket.close if res['connection'] == 'close'
    end

    def do_start
      connect
      @started = true
    end

    def do_finish
    end

    class RTSPResponse < HTTPResponse
      class << self
        def read_status_line(sock)
          str = sock.readline
          m = /^RTSP\/(\d+\.\d+)\s(\d+)\s(.*)$/.match(str)
          m.captures
        end
      end
    end

    class RTSPGenericRequest < HTTPGenericRequest
      def initialize(method)
        @method = method
        @body   = nil
        initialize_http_header nil

        self['User-Agent'] = 'iTunes/4.6 (Macintosh; U; PPC Mac OS X 10.3)'
      end

      def exec(sock, client_id, cseq)
        write_header(sock, client_id, cseq)
        write_body(sock)
      end

      private
      def write_header(sock, client_id, cseq)
        self['Content-Length'] = @body.length.to_s if @body
        url = sprintf("rtsp://%s/%s", sock.io.addr.last, client_id)
        buf = "#{@method} #{url} RTSP/1.0\r\n" +
          "CSeq: #{cseq}\r\n"
        each_capitalized do |k,v|
          buf << "#{k}: #{v}\r\n"
        end
        buf << "\r\n"
        #$stdout.write buf
        sock.write buf
      end

      def write_body(sock)
        #$stdout.write(@body) if @body
        sock.write(@body) if @body
      end
    end

    class Teardown < RTSPGenericRequest
      def initialize
        super('TEARDOWN')
      end
    end

    class SetParameter < RTSPGenericRequest
      def initialize(session_id, opts = {})
        super('SET_PARAMETER')
        self['Content-Type'] = 'text/parameters'
        buf = ''
        opts.each do |k,v|
          buf << "#{k}: #{sprintf('%0.6f', v)}\r\n"
        end
        @body = buf if buf.length > 0
      end
    end

    class Record < RTSPGenericRequest
      def initialize(session_id)
        super('RECORD')
        self['Range']     = 'npt=0-'
        self['RTP-Info']  = 'seq=0;rtptime=0'
        self['Session']   = session_id
      end
    end

    class Setup < RTSPGenericRequest
      def initialize
        super('SETUP')
        self['Transport'] = 'RTP/AVP/TCP;unicast;interleaved=0-1;mode=record'
      end
    end

    class Announce < RTSPGenericRequest
      def initialize(sac, key, iv)
        super('ANNOUNCE')
        @key  = key
        @iv   = iv
        self['Content-Type'] = 'application/sdp'
        self['Apple-Challenge'] = sac.gsub(/[=\s]/, '')
      end

      def write_header(sock, client_id, cseq)
        @body = sprintf(
                "v=0\r\n" +
                "o=iTunes %s 0 IN IP4 %s\r\n" +
                "s=iTunes\r\n" +
                "c=IN IP4 %s\r\n" +
                "t=0 0\r\n" +
                "m=audio 0 RTP/AVP 96\r\n" +
                "a=rtpmap:96 AppleLossless\r\n" +
                "a=fmtp:96 4096 0 16 40 10 14 2 255 0 0 44100\r\n" +
                "a=rsaaeskey:%s\r\n" +
                "a=aesiv:%s\r\n",
                client_id.gsub(/[=\s]/, ''),
                sock.io.addr.last, sock.io.peeraddr.last,
                @key.gsub(/[=\s]/, ""),
                @iv.gsub(/[=\s]/, "" ))
        super(sock, client_id, cseq)
      end
    end
  end
end
