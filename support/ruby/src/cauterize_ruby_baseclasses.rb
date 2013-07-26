
def takeByte!(str)
  byte = str.slice!(0,1)
  raise "Unexpected end of string" if byte == ""
  byte
end

class CauterizeData
  def self.construct(x)
    if x.is_a? CauterizeData
      raise "Invalid Type: was #{x.class}, expected #{c.class}" if not x.is_a? self
      x
    else
      self.new x
    end
  end
end

class CauterizeBuiltin < CauterizeData
  attr_reader :val
  def initialize(val)
    raise "Out of range value" if not in_range(val)
    @val = val
  end
  def to_i
    return @val.to_i
  end
  def to_f
    return @val.to_f
  end
end

class CauterizeScalar < CauterizeData
  attr_reader :val

  def initialize(val)
    @val = self.class.builtin.construct val
  end

  def pack
    @val.pack
  end

  def self.unpack!(str)
    self.new self.builtin.unpack!(str)
  end
end


class CauterizeFixedArray < CauterizeData
  attr_reader :elems

  def initialize(elems)
    @elems = elems.map { |e| self.class.elem_type.construct(e) }
    raise "Invalid length" if @elems.length != self.class.length
  end

  def pack
    @elems.inject("") { |sum, n| sum + n.pack }
  end

  def self.unpack!(str)
    self.new (1..self.length).map { self.elem_type.unpack!(str) }
  end
end


class CauterizeVariableArray < CauterizeData
  attr_reader :length
  attr_reader :elems

  def initialize(elems)
    @elems = elems.map { |e| self.class.elem_type.construct(e) }
    @length = self.class.size_type.new @elems.length
    raise "Invalid length" if @elems.length > self.class.max_length
  end

  def pack
    @length.pack + @elems.inject("") { |sum, n| sum + n.pack }
  end

  def self.unpack!(str)
    length = self.size_type.unpack!(str)
    self.new (1..length.val).map { self.elem_type.unpack!(str) }
  end
end


class CauterizeComposite < CauterizeData
  attr_reader :fields

  def initialize(field_values)
    missing_keys = self.class.fields.keys - field_values.keys
    extra_keys = field_values.keys - self.class.fields.keys
    raise "missing fields #{missing_keys}" if not missing_keys.empty?
    raise "extra fields #{extra_keys}" if not extra_keys.empty?
    @fields = Hash[field_values.map do |field_name, value|
      [field_name, self.class.fields[field_name].construct(value)]
    end]
  end

  def pack
    @fields.values.inject("")  { |sum, v| sum + v.pack }
  end

  def self.unpack!(str)
    self.new Hash[self.fields.keys.map do |k|
      [k, self.fields[k].unpack!(str)]
    end]
  end
end


class CauterizeEnumeration < CauterizeData
  attr_reader :field_name

  def initialize(field_name) @field_name = field_name end

  def val() self.class.fields[@field_name] end

  def pack
    self.class.repr_type.construct(self.class.fields[@field_name]).pack
  end

  def self.from_int(i)
    raise "Invalid enumeration value #{i.to_i}" if not self.fields.values.include? i.to_i
    self.new(self.fields.invert[i.to_i])
  end

  def self.unpack!(str)
    self.from_int(self.repr_type.unpack!(str))
  end
end


class CauterizeGroup < CauterizeData
  attr_reader :tag
  attr_reader :data
  
  def initialize(tag, data = nil)
    @tag = self.class.tag_type.construct(tag)
    if self.class.fields[@tag.field_name].nil?
      @data = data
    else
      @data = self.class.fields[@tag.field_name].construct(data)
    end
  end

  def pack
    @tag.pack + @data.pack
  end

  def self.unpack!(str)
    tag = self.tag_type.unpack!(str)
    data = self.fields[tag.field_name].unpack!(str)
    self.new(tag, data)
  end
end
