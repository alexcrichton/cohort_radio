module Fargo
  module Utils

    # Lord knows why they're doing this...
    def generate_key(lock)
      bytes = []
      bytes << (lock[0] ^ lock[-1] ^ lock[-2] ^ 5)
      (1..lock.length-1).each{ |i| bytes << (lock[i] ^ lock[i - 1]) }
      key = ''
      bytes.each{ |b| key << encode_char(((b << 4) | (b >> 4)) & 0xff) }
      key
    end
  
    # Generates a lock between 80 and 134 random characters, and a pk of 16 random characters.
    def generate_lock
      lock = 'EXTENDEDPROTOCOL'
      # (rand(54) + 64).times{ lock << encode_char(rand(94) + 33) }
      # pk = ''
      # 16.times { pk << encode_char(rand(94) + 33) }
      # [lock, pk]
      [lock + ('ABC' * 6), 'ABCD' * 4]
    end
  
    # Watch out for those special ones...
    def encode_char(c)
      if [0, 5, 36, 96, 124, 126].include? c
        sprintf "/%%DCN%03d%%/", c
      else
        c.chr
      end
    end               
  end
end
