module Net
  class RAOP
    class Client
      class << self
        def encode_alac(bits)
          cb = [32, 0, 2] + bits.unpack("C*")
          i, j = 3, 4
          len = cb.length
          while i < len
            l = cb[i]
            r = cb[j]

            cb[i - 1] |= r >> 7
            cb[i] = (r << 1) | (l >> 7)
            cb[j] = l << 1

            i += 2
            j += 2
          end
          cb.pack("C#{len}")
        end
      end
    end
  end
end
