require 'tmpdir'
require 'fileutils'

module Cauterize
  describe Cauterize::DocBuilder do
    before do
      @tempdir = Dir.mktmpdir
      @doc_path = File.join(@tempdir, "testing.txt")

      @db = DocBuilder.new(@doc_path, "testing")
    end

    after do
      FileUtils.rm_rf @tempdir
    end

    describe :initialize do
      it "should save the name" do
        @db.name.should == "testing"
        @db.doc_path.should == @doc_path
      end
    end

    describe :build do
      before do
        Cauterize.set_version("1.2.3")

        Cauterize.scalar(:an_int, "a useful int") {|t| t.type_name :int32}
        Cauterize.scalar(:another_int) {|t| t.type_name :int32}

        Cauterize.composite(:a_composite, "some useful fields") do |t|
          t.field :an_int, :int32, "a pretty integer"
          t.field :another_int, :int32, "another pretty integer"
          t.field :undescribed, :int32
        end

        Cauterize.composite(:mystery) do |t|
          t.field :undescribed, :int32
        end

        Cauterize.fixed_array(:a_fixed_array, "a few things") do |t|
          t.array_type :an_int
          t.array_size 5
        end

        Cauterize.fixed_array(:a_mystery_array) do |t|
          t.array_type :uint8
          t.array_size 1
        end

        Cauterize.variable_array(:a_var_array, "maybe some things") do |t|
          t.array_type :an_int
          t.array_size 5
          t.size_type :uint8
        end

        Cauterize.variable_array(:a_var_mystery) do |t|
          t.array_type :uint8
          t.array_size 1
          t.size_type :uint8
        end

        Cauterize.enumeration(:some_colors, "several colors to choose from") do |t|
          t.value :red
          t.value :blue
          t.value :green
        end

        Cauterize.enumeration(:mystery_things) do |t|
          t.value :thing1
          t.value :thing2
          t.value :thing3
        end

        Cauterize.group(:oddness, "a mix of weird things") do |t|
          t.field :a_color, :some_colors, "a color"
          t.field :a_cool_int, :int16, "only cool ints fit here"
          t.dataless :a_thing, "only a thing"
          t.dataless :undescribed
        end

        Cauterize.group(:mystery_oddness) do |t|
          t.field :a_color, :some_colors
          t.field :a_cool_int, :int16
          t.dataless :a_thing, "only a thing"
          t.dataless :undescribed
        end

        @db.build
        @doc_text = File.read(@doc_path)
        @doc_lines = @doc_text.lines.to_a
      end

      describe "doc generation" do
        it "contains type details" do
          t = <<EOF
Type Name: int8
Cauterize Class: built-in
Description: <none>
  data - size: 1 bytes

Type Name: int16
Cauterize Class: built-in
Description: <none>
  data - size: 2 bytes

Type Name: int32
Cauterize Class: built-in
Description: <none>
  data - size: 4 bytes

Type Name: int64
Cauterize Class: built-in
Description: <none>
  data - size: 8 bytes

Type Name: uint8
Cauterize Class: built-in
Description: <none>
  data - size: 1 bytes

Type Name: uint16
Cauterize Class: built-in
Description: <none>
  data - size: 2 bytes

Type Name: uint32
Cauterize Class: built-in
Description: <none>
  data - size: 4 bytes

Type Name: uint64
Cauterize Class: built-in
Description: <none>
  data - size: 8 bytes

Type Name: an_int
Cauterize Class: scalar
Description:  - a useful int
  data - type: int32

Type Name: another_int
Cauterize Class: scalar
Description: <none>
  data - type: int32

Type Name: a_composite
Cauterize Class: composite
Description: some useful fields
  an_int - type: int32 - description: a pretty integer
  another_int - type: int32 - description: another pretty integer
  undescribed - type: int32

Type Name: mystery
Cauterize Class: composite
Description: <none>
  undescribed - type: int32

Type Name: a_fixed_array
Cauterize Class: fixed-array
Description: a few things
Stored Type: an_int
Value Count: 5
  data - 5 values of type an_int

Type Name: a_mystery_array
Cauterize Class: fixed-array
Description: <none>
Stored Type: uint8
Value Count: 1
  data - 1 values of type uint8

Type Name: a_var_array
Cauterize Class: variable-array
Description: maybe some things
Maximum Value Count: 5
  length - type uint8
  data - 0 to 5 values of type an_int

Type Name: a_var_mystery
Cauterize Class: variable-array
Description: <none>
Maximum Value Count: 1
  length - type uint8
  data - 0 to 1 values of type uint8

Type Name: some_colors
Cauterize Class: enumeration
Description: several colors to choose from
Encoding: int8
    red = 0
    blue = 1
    green = 2

Type Name: mystery_things
Cauterize Class: enumeration
Description: <none>
Encoding: int8
    thing1 = 0
    thing2 = 1
    thing3 = 2

Type Name: group_oddness_type
Cauterize Class: enumeration
Description: <none>
Encoding: int8
    GROUP_ODDNESS_TYPE_A_COLOR = 0
    GROUP_ODDNESS_TYPE_A_COOL_INT = 1
    GROUP_ODDNESS_TYPE_A_THING = 2
    GROUP_ODDNESS_TYPE_UNDESCRIBED = 3

Type Name: oddness
Cauterize Class: group
Description: a mix of weird things
  kind tag: group_oddness_type
  kinds:
    a_color - payload: some_colors - description: a color
    a_cool_int - payload: int16 - description: only cool ints fit here
    a_thing - payload: <no payload> - description: only a thing
    undescribed - payload: <no payload>

Type Name: group_mystery_oddness_type
Cauterize Class: enumeration
Description: <none>
Encoding: int8
    GROUP_MYSTERY_ODDNESS_TYPE_A_COLOR = 0
    GROUP_MYSTERY_ODDNESS_TYPE_A_COOL_INT = 1
    GROUP_MYSTERY_ODDNESS_TYPE_A_THING = 2
    GROUP_MYSTERY_ODDNESS_TYPE_UNDESCRIBED = 3

Type Name: mystery_oddness
Cauterize Class: group
Description: <none>
  kind tag: group_mystery_oddness_type
  kinds:
    a_color - payload: some_colors
    a_cool_int - payload: int16
    a_thing - payload: <no payload> - description: only a thing
    undescribed - payload: <no payload>
EOF
          @doc_text.should == t
        end
      end
    end
  end

end
