module Cauterize::Builders::Ruby
  class VariableArray < Buildable
    def render
      @blueprint.name.to_s.camel
    end

    def class_defn(f)
      array_type_bldr = Cauterize::Builders.get(:ruby, @blueprint.array_type)
      size_type_bldr = Cauterize::Builders.get(:ruby, @blueprint.size_type)
      x = <<EOF
class #{render} < CauterizeVariableArray
  def self.size_type () #{size_type_bldr.render} end
  def self.max_length () #{@blueprint.array_size} end
  def self.elem_type() #{array_type_bldr.render} end
end
EOF
      f << x
    end
  end
end

Cauterize::Builders.register(:ruby, Cauterize::VariableArray, Cauterize::Builders::Ruby::VariableArray)
