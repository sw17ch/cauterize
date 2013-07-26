module Cauterize::Builders::Ruby
  class Scalar < Buildable
    def render
      @blueprint.name.to_s.camel
    end

    def class_defn(f)
      tn_bldr = Cauterize::Builders.get(:ruby, @blueprint.type_name)
      x = <<EOF
class #{render} < CauterizeScalar
  def self.builtin() #{tn_bldr.render} end
end
EOF
      f << x
    end
  end
end

Cauterize::Builders.register(:ruby, Cauterize::Scalar, Cauterize::Builders::Ruby::Scalar)
