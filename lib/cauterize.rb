require 'bindata'
require 'cauterize/snake_case'
require 'cauterize/base_type'
require 'cauterize/cauterize'

def fix(s)
  s.gsub(/([[:alpha:]])_([[:digit:]])/) do |m|
    $1 + $2
  end
end


def populate_scalar(klass, inst)
  klass.class_eval do
    endian :little
    send(fix(inst.type_name.name.to_s), :data)
  end
end

def populate_enum(klass, inst)
  klass.class_eval do
    endian :little

    send(fix(inst.representation.name.to_s), :representation)

    enum_vals = inst.values.values.map {|v| [v.value, v.name.to_sym]}
    enum_hash = Hash[enum_vals]
    const_set(:ENUM_MAP, enum_hash)
    inst.values.values.each do |v| 
      klass.const_set(v.name.upcase.to_sym, v.value)
    end

    def enum
      self.class.const_get(:ENUM_MAP)[representation]
    end
  end
end

def populate_fixed_array(klass, inst)
  klass.class_eval do
    endian :little
    array :data, { :type => fix(inst.array_type.name.to_s),
                   :initial_length => inst.array_size }
  end
end

def populate_variable_array(klass, inst)
  # TODO: Figure out what we should do with inst.array_size
  klass.class_eval do
    endian :little
    send(fix(inst.size_type.name.to_s), :va_len, :value => lambda { data.length })
    array :data, { :type => fix(inst.array_type.name.to_s),
                   :read_until => lambda { index == va_len - 1}}
  end
end

def populate_composite(klass, inst)
  klass.class_eval do
    endian :little
    inst.fields.values.each do |v|
      send(fix(v.type.name.to_s), v.name.to_s)
    end
  end
end

def populate_group(klass, inst)
  choices = inst.fields.values.each_with_index.map do |v, i|
    [i, v.type.nil? ? :empty_data : fix(v.type.name.to_s).to_sym]
  end

  klass.class_eval do
    endian :little
    send(fix(inst.tag_enum.name.to_s), :tag)

    choice :data, :selection => lambda { tag.representation },
                  :choices => Hash[choices]
  end
end
 
module Cauterize
  class EmptyData < BinData::Record; end

  def self.populate(desc_file)
    parse_dsl(desc_file)

    dsl_mod = Module.new do |mod|

      BaseType.all_instances.each do |inst|
        next if Cauterize::BuiltIn == inst.class

        n = inst.name.to_s.camel
        module_eval("class #{n} < BinData::Record; end")
        klass = const_get(n)

        case inst
        when Cauterize::Scalar
          populate_scalar(klass, inst)
        when Cauterize::Enumeration
          populate_enum(klass, inst)
        when Cauterize::FixedArray
          populate_fixed_array(klass, inst)
        when Cauterize::VariableArray
          populate_variable_array(klass, inst)
        when Cauterize::Composite
          populate_composite(klass, inst)
        when Cauterize::Group
          populate_group(klass, inst)
        else
          puts "Unhandled instance: #{inst.class.name}"
        end
      end
    end

    const_set(Cauterize.get_name.camel, dsl_mod)
  end
end

