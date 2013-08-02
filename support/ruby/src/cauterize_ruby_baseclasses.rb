require 'stringio'

class CauterizeData
  def self.construct(x)
    if x.is_a? CauterizeData
      raise "Invalid Type: was #{x.class}, expected #{self.name}" if not x.is_a?(self)
      x
    else
      self.new x
    end
  end

  def self.unpack(x)
    self.unpackio(StringIO.new(x))
  end
end

class CauterizeBuiltin < CauterizeData
  def initialize(val)
    raise "Out of range value" if not in_range(val)
    @val = val
  end
  def to_ruby
    @val
  end
end

class CauterizeBuiltinInteger < CauterizeBuiltin
  def initialize(val)
    super(val.to_i)
  end

  def to_i
    @val
  end
end

class CauterizeBuiltinFloat < CauterizeBuiltin
  def initialize(val)
    super(val.to_f)
  end

  def to_f
    @val
  end
end

class CauterizeBuiltinBool < CauterizeBuiltin
  def initialize(val)
    super((val)? true : false)
  end
end


class CauterizeScalar < CauterizeData
  def initialize(val)
    @val = self.class.builtin.construct val
  end

  def to_ruby
    @val.to_ruby
  end

  def pack
    @val.pack
  end

  def self.unpackio(str)
    self.new self.builtin.unpackio(str)
  end
end

class CauterizeArray < CauterizeData
  def to_ruby
    @elems.map{|e| e.to_ruby}
  end

  def to_string
    to_ruby.to_a.pack("C*")
  end
end

class CauterizeFixedArray < CauterizeArray
  attr_reader :elems

  def initialize(elems)
    @elems = elems.map { |e| self.class.elem_type.construct(e) }
    raise "Invalid length" if @elems.length != self.class.length
  end

  def pack
    @elems.inject("") { |sum, n| sum + n.pack }
  end

  def self.unpackio(str)
    self.new (1..self.length).map { self.elem_type.unpackio(str) }
  end
end


class CauterizeVariableArray < CauterizeArray
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

  def self.unpackio(str)
    length = self.size_type.unpackio(str)
    self.new (1..length.to_i).map { self.elem_type.unpackio(str) }
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

  def to_ruby
    Hash[@fields.map{|name, value| [name, value.to_ruby]}]
  end

  def pack
    @fields.values.inject("")  { |sum, v| sum + v.pack }
  end

  def self.unpackio(str)
    self.new Hash[self.fields.keys.map do |k|
      [k, self.fields[k].unpackio(str)]
    end]
  end

  alias orig_method_missing method_missing

  def method_missing(m, *args, &block)
    if fields[m]
      fields[m]
    else
      orig_method_missing(m, *args, &block)
    end
  end
end


class CauterizeEnumeration < CauterizeData
  attr_reader :field_name

  def initialize(field_name)
    raise "Invalid field name #{field_name}" if not self.class.fields.keys.include?(field_name)
    @field_name = field_name
  end

  def to_ruby
    @field_name
  end

  def to_i() self.class.fields[@field_name] end

  def pack
    self.class.repr_type.construct(self.class.fields[@field_name]).pack
  end

  def self.from_int(i)
    raise "Invalid enumeration value #{i.to_i}" if not self.fields.values.include? i.to_i
    self.new(self.fields.invert[i.to_i])
  end

  def self.unpackio(str)
    self.from_int(self.repr_type.unpackio(str).to_i)
  end
end


class CauterizeGroup < CauterizeData
  attr_reader :tag
  attr_reader :data

  def to_ruby
    if data.nil?
      { tag: tag_field_name }
    else
      { tag: tag_field_name,
        data: data.to_ruby }
    end
  end

  def tag_field_name
    self.class.from_tag_field_name(@tag.field_name)
  end

  def self.tag_from_field_name(field_name)
    self.tag_type.construct((self.tag_prefix + field_name.to_s).to_sym)
  end

  def self.from_tag_field_name(tag_name)
    t = tag_name.to_s
    t.slice!(self.tag_prefix)
    t.to_sym
  end
  
  def initialize(h)
    @tag = self.class.tag_from_field_name(h[:tag])

    field_class = self.class.fields[tag_field_name]
    if field_class.nil?
      @data = nil
    else
      @data = field_class.construct(h[:data])
    end
  end

  def pack
    if @data.nil?
      @tag.pack
    else
      @tag.pack + @data.pack
    end
  end

  def self.unpackio(str)
    tag = self.tag_type.unpackio(str)
    field_name = self.from_tag_field_name(tag.field_name)
    data_type = self.fields[field_name]
    if data_type.nil?
      self.new({ tag: field_name })
    else
      self.new({ tag: field_name, data: data_type.unpackio(str) })
    end
  end
end
