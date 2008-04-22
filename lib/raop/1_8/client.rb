module Net
  class RAOP
    class Client
      class << self
        @@decode_cache = "\0" * 16384

        def decode_alac(bits)
          len = bits.length
          new_bits = len == 16387 ? @@decode_cache.dup : "\0" * bits.length - 3

          i = 0
          while i < len - 3
            middle = bits[i + 3]
            new_bits[i + 1] |= ((bits[i + 2] & 0x01) << 7) | ((middle & 0xFE) >> 1)
            new_bits[i] |= ((middle & 0x01) << 7) | ((bits[i + 4] & 0xFE) >> 1)
            i += 2
          end
          new_bits
        end

        def encode_alac(bits)
          cb = HEADER + bits
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
          cb
        end
      end
    end
  end
end
