module Cauterize::Builders::Ruby
  class Enumeration < Buildable
    def render
      @blueprint.name.to_s.camel
    end

    def class_defn(f)
      rep_builder = Cauterize::Builders.get(:ruby, @blueprint.representation)
      f << "class #{render} < CauterizeEnumeration"
      f << "  def self.repr_type() #{rep_builder.render} end"
      f << "  def self.fields"
      f << "    {"
      @blueprint.values.values.each do |v|
        f << "      #{v.name.to_s.upcase}: #{v.value},"
      end
      f << "    }"
      f << "  end"
      @blueprint.values.values.each do |v|
        f << "  #{v.name.to_s.upcase} = #{render}.new(:#{v.name.to_s.upcase})"
      end
      f << "end"
      f << ""
    end
  end
end

Cauterize::Builders.register(:ruby, Cauterize::Enumeration, Cauterize::Builders::Ruby::Enumeration)
