require_relative './cauterize_ruby_baseclasses'

class UInt8 < CauterizeBuiltinInteger
  def in_range(v) v >= 0 && v < 2**8 end
  def pack
    [to_i].pack("C")
  end
  def self.unpackio(str)
    UInt8.new str.read(1).unpack("C")[0]
  end
end

class UInt16 < CauterizeBuiltinInteger
  def in_range(v) v >= 0 && v < 2**16 end
  def pack
    [to_i].pack("S")
  end
  def self.unpackio(str)
    UInt16.new str.read(2).unpack("S")[0]
  end
end

class UInt32 < CauterizeBuiltinInteger
  def in_range(v) v >= 0 && v < 2**32 end
  def pack
    [to_i].pack("L")
  end
  def self.unpackio(str)
    UInt32.new str.read(4).unpack("L")[0]
  end
end

class UInt64 < CauterizeBuiltinInteger
  def in_range(v) v >= 0 && v < 2**64 end
  def pack
    [to_i].pack("Q")
  end
  def self.unpackio(str)
    UInt64.new str.read(8).unpack("Q")[0]
  end
end

class Int8 < CauterizeBuiltinInteger
  def in_range(v) (v >= -2**7) && (v < 2**7) end
  def pack
    [to_i].pack("c")
  end
  def self.unpackio(str)
    Int8.new str.read(1).unpack("c")[0]
  end
end

class Int16 < CauterizeBuiltinInteger
  def in_range(v) (v >= -2**15) && (v < 2**15) end
  def pack
    [to_i].pack("s")
  end
  def self.unpackio(str)
    Int16.new str.read(2).unpack("s")[0]
  end
end

class Int32 < CauterizeBuiltinInteger
  def in_range(v) (v >= -2**31) && (v < 2**31) end
  def pack
    [to_i].pack("l")
  end
  def self.unpackio(str)
    Int32.new str.read(4).unpack("l")[0]
  end
end

class Int64 < CauterizeBuiltinInteger
  def in_range(v) (v >= -2**63) && (v < 2**63) end
  def pack
    [to_i].pack("q")
  end
  def self.unpackio(str)
    Int64.new str.read(8).unpack("q")[0]
  end
end

class Bool < CauterizeBuiltinBool
  def in_range(v) true end
  def pack
    if @val
      [1].pack("C")
    else
      [0].pack("C")
    end
  end
  def self.unpackio(str)
    if str.read(1).unpack("C")[0] == 0
      Bool.new false
    else
      Bool.new true
    end
  end
end

class Float32 < CauterizeBuiltinFloat
  def in_range(v) v > (-3.402823466e38) && v < (3.402823466e38) end
  def pack
    [to_f].pack("f")
  end
  def self.unpackio(str)
    Float32.new str.read(4).unpack("f")[0]
  end
end

class Float64 < CauterizeBuiltinFloat
  def in_range(v) true end
  def pack
    [to_f].pack("d")
  end
  def self.unpackio(str)
    Float64.new str.read(8).unpack("d")[0]
  end
end



