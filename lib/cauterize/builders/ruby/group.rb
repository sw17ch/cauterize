module Cauterize::Builders::Ruby
  class Group < Buildable
    def render
      @blueprint.name.to_s.camel
    end
    def initialize(blueprint)
      super(blueprint)
      @tag_enum = blueprint.tag_enum
    end

    def class_defn(f)
      tag = Cauterize::Builders.get(:ruby, @tag_enum).render

      f << "class #{render} < CauterizeGroup"
      f << "  def self.tag_type() #{tag} end"
      f << "  def self.tag_prefix() '#{@blueprint.tag_enum.name.upcase}_' end"
      f << "  def self.fields"
      f << "    {"
      @blueprint.fields.values.each_with_index do |field, i|
        if field.type
          t = Cauterize::Builders.get(:ruby, field.type).render
          f << "      #{field.name.to_s.upcase}: #{t},"
        else
          f << "      #{field.name.to_s.upcase}: nil,"
        end
      end
      f << "    }"
      f << "  end"
      f << "end"
      f << ""
    end
  end
end

Cauterize::Builders.register(:ruby, Cauterize::Group, Cauterize::Builders::Ruby::Group)
