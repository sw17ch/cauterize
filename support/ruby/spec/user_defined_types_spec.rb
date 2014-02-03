require 'tmpdir'
require 'fileutils'

require_relative '../src/cauterize_ruby_builtins'

module Cauterize

  describe "various derived user types" do

    let!(:test_proj_dir) { Dir.mktmpdir("test_proj_1") }
    let(:app_root) { File.expand_path(File.dirname(__FILE__) + "/../../..") }
    let(:cauterize_tool) { "#{app_root}/bin/cauterize" }

   
    before do
      FileUtils.cd test_proj_dir do
        # Write Cauterize file
        File.open("Cauterize","w") do |f|
          f.puts cauterize_file_text
        end
        # Run the tool to generate Ruby lib code
        system %{#{cauterize_tool} generate ruby test1}
  
        # Load the lib code
        $LOAD_PATH << "#{test_proj_dir}/test1"
        require 'test1'
      end
    end

    after do
      FileUtils.remove_entry_secure test_proj_dir
    end

    it "works" do
      
      #
      # SCALAR
      #
      b = Test1Byte.new(255)
      Test1Byte.unpack(b.pack).to_ruby.should == 255

      i = Test1Int.new(-200)
      Test1Int.unpack(i.pack).to_ruby.should == -200

      #
      # ENUMERATION
      #
      c = Test1Color::RED
      Test1Color.unpack(c.pack).to_ruby.should == :RED

      c2 = Test1Color::GREEN
      Test1Color.unpack(c2.pack).to_ruby.should == :GREEN

      #
      # COMPOSITE
      #
      #   Regression test: :test1_dot declares that the :color field 
      #   comes before the x and y values.  Since this is a Ruby Hash literal,
      #   we should be allowed to specify the keys in any order we like as long 
      #   as all are present.
      #
      loc = Test1Dot.new(
        x: 100,
        y: 200,
        color: :BLUE  # defined as first, should be ok to specify it last.
      )
      loc.color.class.should == Test1Color
      loc.color.to_ruby.should == :BLUE
      loc.x.to_ruby.should == 100
      loc.y.to_ruby.should == 200

      loc.pack.should == loc.color.pack + loc.x.pack + loc.y.pack

      loc2 = Test1Dot.unpack(loc.pack)
      loc2.color.class.should == Test1Color
      loc2.color.to_ruby.should == :BLUE
      loc2.x.to_ruby.should == 100
      loc2.y.to_ruby.should == 200

      #
      # FIXED ARRAY
      #
      tri = Test1Tri.new([{x:10,y:20,color: :RED},
                         {x:30,y:40,color: :GREEN},
                         {x:50,y:60,color: :BLUE}])
      tri2 = Test1Tri.unpack(tri.pack)
      tri2.to_ruby.should == tri.to_ruby

      #
      # VARIABLE ARRAY
      #
      str = Test1ByteString.new( "hello".bytes.to_a )
      get_byte(str.pack, 0).should == 5 # length field sneaks in at the front of the list
      str2 = Test1ByteString.unpack(str.pack)
      str2.to_ruby.should == [104, 101, 108, 108, 111]

      # See we can't put an 11-length string in there:
      lambda do Test1ByteString.new( "0123456789_".bytes.to_a ) end.should raise_error(/invalid length/i)

      #
      # GROUP
      #

    end

    # TODO test:
    # Group

    #
    # HELPERS
    # 

    def get_byte(str,idx)
      str.bytes.to_a[idx]
    end

    def expect_out_of_range(&block)
      block.should raise_error(/Out of range value/)
    end

    def cauterize_file_text 
      @cauterize_file_text ||=<<-EOF
        set_name("test1")
        set_version("1.2.3")

        scalar(:test1_int)  { |t| t.type_name(:int32) }
        scalar(:test1_byte) { |t| t.type_name(:uint8) }

        enumeration(:test1_color) do |e|
          e.value :red
          e.value :blue
          e.value :green
        end

        composite(:test1_dot) do |c|
          c.field :color, :test1_color
          c.field :x, :test1_int
          c.field :y, :test1_int
        end

        fixed_array(:test1_tri) do |a|
          a.array_type :test1_dot
          a.array_size 3
        end

        variable_array(:test1_byte_string) do |a|
          a.array_type :test1_byte
          a.size_type :uint8
          a.array_size 10 
        end
        
      EOF
    end
  end # describe user types
end # Cauterize module
