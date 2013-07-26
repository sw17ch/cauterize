require 'tmpdir'
require 'fileutils'

module Cauterize
  describe Cauterize::RubyBuilder do
    before do
      @tempdir = Dir.mktmpdir
      @rb_path = File.join(@tempdir, "testing.rb")

      @rb = RubyBuilder.new(@rb_path, "testing")
    end

    describe :build do
      before do
        Cauterize.set_version("1.2.3")

        Cauterize.scalar(:small_uint) {|t| t.type_name(:uint8)}

        Cauterize.fixed_array(:mac_address) do |fa|
          fa.array_type :small_uint
          fa.array_size 6
        end

        Cauterize.variable_array(:mac_table) do |t|
          t.array_type :mac_address
          t.array_size 64
          t.size_type :small_uint
        end

        Cauterize.variable_array(:name) do |va|
          va.array_type :small_uint
          va.size_type :small_uint
          va.array_size 32
        end

        Cauterize.enumeration(:gender) do |e|
          e.value :male
          e.value :female
        end

        Cauterize.composite(:place) do |c|
          c.field :name, :name
          c.field :elevation, :uint32
        end

        Cauterize.composite(:person) do |c|
          c.field :first_name, :name
          c.field :last_name, :name
          c.field :gender, :gender
        end

        Cauterize.composite(:dog) do |c|
          c.field :name, :name
          c.field :gender, :gender
          c.field :leg_count, :small_uint
        end

        Cauterize.group(:creature) do |g|
          g.field :person, :person
          g.field :dog, :dog
        end

        @rb.build
        @ruby_text = File.read(@rb.rb)
        puts @ruby_text
        @ruby_lines = @ruby_text.lines.to_a
      end

      describe "header generation" do
        it "informs the user the code is generated" do
          @ruby_text.should include("generated code. Do not edit")
        end

        it "requires 'cauterize_ruby_baseclasses'" do
          @ruby_text.should include("require_relative './cauterize_ruby_baseclasses'")
        end

      end
    end
  end
end
