
def takeBytes!(num_bytes, str)
  byte = str.slice!(0, num_bytes)
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

  def method_missing(m, *args, &block)
    fields[m]
  end
end


class CauterizeEnumeration < CauterizeData
  attr_reader :field_name

  def initialize(field_name)
    raise "Invalid field name #{field_name}" if not self.class.fields.keys.include?(field_name)
    @field_name = field_name
  end

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

  def to_tag_name(field_name)
    (self.class.tag_prefix + field_name.to_s).to_sym
  end

  def self.from_field_name(tag_name)
    t = tag_name.to_s
    t.slice!(self.tag_prefix)
    t.to_sym
  end
  
  def initialize(tag, data = nil)
    @tag = self.class.tag_type.construct(to_tag_name(tag))
    field_class = self.class.fields[self.class.from_field_name(@tag.field_name)]
    if field_class.nil?
      @data = data
    else
      @data = field_class.construct(data)
    end
  end

  def pack
    if @data.nil?
      @tag.pack
    else
      @tag.pack + @data.pack
    end
  end

  def self.unpack!(str)
    tag = self.tag_type.unpack!(str)
    field_name = self.from_field_name(tag.field_name)
    data = self.fields[field_name]
    if data.nil?
      self.new(field_name)
    else
      self.new(field_name, data.unpack!(str))
    end
  end
end
