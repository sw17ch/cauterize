require_relative './cauterize_ruby_baseclasses'

class UInt8 < CauterizeBuiltin
  def in_range(v) v >= 0 && v < 2**8 end
  def pack
    [val.to_i].pack("C")
  end
  def self.unpack!(str)
    UInt8.new takeBytes!(1, str).unpack("C")[0]
  end
end

class UInt16 < CauterizeBuiltin
  def in_range(v) v >= 0 && v < 2**16 end
  def pack
    [val.to_i].pack("S")
  end
  def self.unpack!(str)
    UInt16.new takeBytes!(2, str).unpack("S")[0]
  end
end

class UInt32 < CauterizeBuiltin
  def in_range(v) v >= 0 && v < 2**32 end
  def pack
    [val.to_i].pack("L")
  end
  def self.unpack!(str)
    UInt32.new takeBytes!(4, str).unpack("L")[0]
  end
end

class UInt64 < CauterizeBuiltin
  def in_range(v) v >= 0 && v < 2**64 end
  def pack
    [val.to_i].pack("Q")
  end
  def self.unpack!(str)
    UInt64.new takeBytes!(8, str).unpack("Q")[0]
  end
end

class Int8 < CauterizeBuiltin
  def in_range(v) (v >= -2**7) && (v < 2**7) end
  def pack
    [val.to_i].pack("c")
  end
  def self.unpack!(str)
    Int8.new takeBytes!(1, str).unpack("c")[0]
  end
end

class Int16 < CauterizeBuiltin
  def in_range(v) (v >= -2**15) && (v < 2**15) end
  def pack
    [val.to_i].pack("s")
  end
  def self.unpack!(str)
    Int16.new takeBytes!(2, str).unpack("s")[0]
  end
end

class Int32 < CauterizeBuiltin
  def in_range(v) (v >= -2**31) && (v < 2**31) end
  def pack
    [val.to_i].pack("l")
  end
  def self.unpack!(str)
    Int32.new takeBytes!(4, str).unpack("l")[0]
  end
end

class Int64 < CauterizeBuiltin
  def in_range(v) (v >= -2**63) && (v < 2**63) end
  def pack
    [val.to_i].pack("q")
  end
  def self.unpack!(str)
    Int64.new takeBytes!(8, str).unpack("q")[0]
  end
end

class Bool < CauterizeBuiltin
  def in_range(v) true end
  def pack
    if @val
      [1].pack("C")
    else
      [0].pack("C")
    end
  end
  def self.unpack!(str)
    if takeBytes!(1, str).unpack("C")[0] == 0
      Bool.new false
    else
      Bool.new true
    end
  end
end

class Float32 < CauterizeBuiltin
  def in_range(v) v > (-3.402823466e38) && v < (3.402823466e38) end
  def pack
    [val.to_f].pack("f")
  end
  def self.unpack!(str)
    Float32.new takeBytes!(4, str).unpack("f")[0]
  end
end

class Float64 < CauterizeBuiltin
  def in_range(v) true end
  def pack
    [val.to_f].pack("d")
  end
  def self.unpack!(str)
    Float64.new takeBytes!(8, str).unpack("d")[0]
  end
end



