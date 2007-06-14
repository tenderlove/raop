class Array
  @@masks = [
    0x01, 0x03, 0x07, 0x0F,
    0x1F, 0x3F, 0x7F, 0xff
  ]

  def add_alac(i,data)
    self[i] |= data >> 7
    self[i + 1] |= (data & 0x7F) << 1
  end
end

