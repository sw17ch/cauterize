module Cauterize::Builders::Ruby
  class FixedArray < Buildable
    def render
      @blueprint.name.to_s.camel
    end

    def class_defn(f)
      array_type_bldr = Cauterize::Builders.get(:ruby, @blueprint.array_type)
      x = <<EOF
class #{render} < CauterizeFixedArray
  def self.length () #{@blueprint.array_size} end
  def self.elem_type() #{array_type_bldr.render} end
end
EOF
      f << x
    end
  end
end

Cauterize::Builders.register(:ruby, Cauterize::FixedArray, Cauterize::Builders::Ruby::FixedArray)
