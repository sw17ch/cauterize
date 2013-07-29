module Cauterize::Builders::Ruby
  class BuiltIn < Buildable
    @@RUBY_TYPE_MAPPING = {
      1 => {signed: "Int8",  unsigned: "UInt8",  :float => nil,       :bool => "Bool"},
      2 => {signed: "Int16", unsigned: "UInt16", :float => nil,       :bool => nil},
      4 => {signed: "Int32", unsigned: "UInt32", :float => "Float32", :bool => nil},
      8 => {signed: "Int64", unsigned: "UInt64", :float => "Float64", :bool => nil},
    }

    def render
      render_rbtype
    end

    def class_defn(f)
    end

    private

    def render_rbtype
      @@RUBY_TYPE_MAPPING[@blueprint.byte_length][@blueprint.flavor]
    end
  end
end

Cauterize::Builders.register(:ruby, Cauterize::BuiltIn, Cauterize::Builders::Ruby::BuiltIn)
