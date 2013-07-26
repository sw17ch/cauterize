require "require_all"

lib_path = File.dirname(__FILE__) + "/.."
require_all Dir[lib_path + "/**/*.rb"]

module Cauterize

  module_function
  def generate(language, target_dir, desc_file)
    parse_dsl(desc_file)
    FileUtils.mkdir_p(target_dir)
    output_prefix = get_name || "generated_interface"
    builder = send "make_builder_#{language}".to_sym, target_dir, output_prefix
    builder.build
  end

  # Generate the C code corresponding to the generated configuration
  def make_builder_c(target_dir, output_prefix)
    h_file = File.join(target_dir, "#{output_prefix}.h")
    c_file = File.join(target_dir, "#{output_prefix}.c")

    Cauterize::CBuilder.new(h_file, c_file, output_prefix)
  end

  # Generate the CS code corresponding to the generated configuration
  def make_builder_cs(target_dir, output_prefix)
    cs_file = File.join(target_dir, "#{output_prefix}.cs")

    Cauterize::CSBuilder.new(cs_file, output_prefix)
  end

  # Generate the Ruby code corresponding to the generated configuration
  def make_builder_ruby(target_dir, output_prefix)
    rb_file = File.join(target_dir, "#{output_prefix}.rb")

    Cauterize::RubyBuilder.new(rb_file, output_prefix)
  end

  def make_builder_doc(target_dir, output_prefix)
    doc_file = File.join(target_dir, "#{output_prefix}.txt")

    Cauterize::DocBuilder.new(doc_file, output_prefix)
  end

  def get_name
    @@description_name
  end

  def get_version
    if defined? @@version
      @@version
    else
      "UNDEFINED"
    end
  end

  def set_name(desc_name)
    @@description_name = desc_name
  end

  def set_version(version)
    @@version = version
  end

  def parse_dsl(desc_file)
    Object.new.extend(Cauterize).instance_exec do
      # this magic allows us to emit useful exception messages when evaling the
      # file. if your description file has errors, you'll be able to find them
      # because of this magic.
      p = Proc.new {}
      eval(File.read(desc_file), p.binding, desc_file)
    end

  end

end
