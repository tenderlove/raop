class Net::RAOP::BitBuffer < Array
  @@masks = [
    0x01, 0x03, 0x07, 0x0F,
    0x1F, 0x3F, 0x7F, 0xff
  ]

  def initialize(*args, &block)
    super(*args, &block)
    @bit_offset  = 0
    @byte_offset = 0
  end

  def write_bits(data, numbits)
    if @bit_offset != 0 && @bit_offset + numbits > 8
      num_write_bits = 8 - @bit_offset
      bits_to_write  = (data >> (numbits - num_write_bits)) <<
        (8 - @bit_offset - num_write_bits)
      self[@byte_offset] |= bits_to_write
      numbits -= num_write_bits
      @bit_offset = 0
      @byte_offset += 1
    end

    while numbits >= 8
      bits_to_write = (data >> (numbits - 8)) & 0xFF
      self[@byte_offset] |= bits_to_write
      numbits -= 8
      @bit_offset = 0
      @byte_offset += 1
    end

    if numbits > 0
      bits_to_write = (data & @@masks[numbits]) <<
        (8 - @bit_offset - numbits)
      self[ @byte_offset ] |= bits_to_write
      @bit_offset += numbits
      if @bit_offset == 8
        @byte_offset += 1
        @bit_offst = 0
      end
    end
  end
end

