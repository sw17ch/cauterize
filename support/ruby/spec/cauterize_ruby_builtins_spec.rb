require 'tmpdir'
require 'fileutils'

require_relative '../src/cauterize_ruby_builtins'

module Cauterize

  describe "Cauterize's Ruby built-ins" do
    def get_byte(str,idx)
      str.bytes.to_a[idx]
    end

    def expect_out_of_range(&block)
      block.should raise_error(/Out of range value/)
    end

    describe "Bool" do
      it "can be instantiated, packed and unpacked" do
        x = Bool.new(true)
        x.to_ruby.should == true

        s = x.pack
        get_byte(s,0).should == 1

        y = Bool.unpack(s) 
        y.to_ruby.should == true

        # False:
        x = Bool.new(false)
        x.to_ruby.should == false

        s = x.pack
        get_byte(s,0).should == 0

        y = Bool.unpack(s) 
        y.to_ruby.should == false
      end
    end

    describe "UInt8" do
      it "can be instantiated, packed and unpacked" do
        x = UInt8.new(42)
        x.to_ruby.should == 42

        s = x.pack
        get_byte(s,0).should == 42

        y = UInt8.unpack(s) 
        y.to_ruby.should == 42
      end

      it "rejects out-of-range values" do
        expect_out_of_range do UInt8.new(-1) end
        expect_out_of_range { UInt8.new(256) }
      end
    end

    describe "UInt16" do
      it "can be instantiated, packed and unpacked" do
        x = UInt16.new(0xABCD)
        x.to_ruby.should == 0xABCD

        s = x.pack
        get_byte(s,0).should == 0xCD # little endien
        get_byte(s,1).should == 0xAB

        y = UInt16.unpack(s) 
        y.to_ruby.should == 0xABCD
      end

      it "rejects out-of-range values" do
        expect_out_of_range do UInt16.new(-1) end
        expect_out_of_range { UInt16.new(0x10000) }
      end
    end

    describe "UInt32" do
      it "can be instantiated, packed and unpacked" do
        num = 0xDEADBEEF
        x = UInt32.new(num)
        x.to_ruby.should == num

        s = x.pack
        get_byte(s,0).should == 0xEF # little endien
        get_byte(s,1).should == 0xBE
        get_byte(s,2).should == 0xAD
        get_byte(s,3).should == 0xDE

        y = UInt32.unpack(s) 
        y.to_ruby.should == num
      end

      it "rejects out-of-range values" do
        expect_out_of_range do UInt32.new(-1) end
        expect_out_of_range { UInt32.new(2**32) }
      end
    end

    describe "UInt64" do
      it "can be instantiated, packed and unpacked" do
        num = 0xCAFEBABEDEADBEEF
        x = UInt64.new(num)
        x.to_ruby.should == num

        s = x.pack
        get_byte(s,0).should == 0xEF # little endien
        get_byte(s,1).should == 0xBE
        get_byte(s,2).should == 0xAD
        get_byte(s,3).should == 0xDE
        get_byte(s,4).should == 0xBE 
        get_byte(s,5).should == 0xBA
        get_byte(s,6).should == 0xFE
        get_byte(s,7).should == 0xCA

        y = UInt64.unpack(s) 
        y.to_ruby.should == num
      end

      it "rejects out-of-range values" do
        expect_out_of_range do UInt64.new(-1) end
        expect_out_of_range { UInt64.new(2**64) }
      end
    end

    describe "Int8" do
      it "can be instantiated, packed and unpacked" do
        x = Int8.new(42)
        x.to_ruby.should == 42

        s = x.pack
        get_byte(s,0).should == 42

        y = Int8.unpack(s) 
        y.to_ruby.should == 42
      end

      it "handles negative vals" do
        x = Int8.new(-42)
        x.to_ruby.should == -42
        s = x.pack
        get_byte(s,0).should == 0xD6
      end

      it "rejects out-of-range values" do
        expect_out_of_range do Int8.new(-129) end
        expect_out_of_range { Int8.new(128) }
      end
    end

    describe "Int16" do
      it "can be instantiated, packed and unpacked" do
        x = Int16.new(0xBCD)
        x.to_ruby.should == 0xBCD

        s = x.pack
        get_byte(s,0).should == 0xCD # little endien
        get_byte(s,1).should == 0x0B

        y = Int16.unpack(s) 
        y.to_ruby.should == 0xBCD
      end

      it "handles negative vals" do
        x = Int16.new(-42)
        x.to_ruby.should == -42
        s = x.pack
        get_byte(s,0).should == 0xD6
      end

      it "rejects out-of-range values" do
        expect_out_of_range do Int16.new(-32769) end
        expect_out_of_range { Int16.new(32768) }
      end
    end

    describe "Int32" do
      it "can be instantiated, packed and unpacked" do
        num = 0xDEADBEE
        x = Int32.new(num)
        x.to_ruby.should == num

        s = x.pack
        get_byte(s,0).should == 0xEE # little endien
        get_byte(s,1).should == 0xDB
        get_byte(s,2).should == 0xEA
        get_byte(s,3).should == 0x0D

        y = Int32.unpack(s) 
        y.to_ruby.should == num
      end

      it "handles negative vals" do
        x = Int32.new(-42)
        x.to_ruby.should == -42
        s = x.pack
        get_byte(s,0).should == 0xD6
      end

      it "rejects out-of-range values" do
        edge = 2**31
        Int32.new(-edge) # lower edge of ok
        Int32.new(edge-1) # upper edge of ok
        expect_out_of_range do Int32.new(-(edge+1)) end
        expect_out_of_range { Int32.new(edge) }
      end
    end

    describe "Float32" do
      it "can be instantiated, packed and unpacked" do
        [ -123.456, 3001.4001, 42.424242 ].each do |num|
          obj = Float32.new(num)
          obj.to_ruby.should == num
          str = obj.pack
          str.length.should == 4
          Float32.unpack(str).to_ruby.should be_within(0.0001).of(num)
        end
      end

      it "rejects out-of-range values" do
        lower_not_ok = -3.402823466e38
        upper_not_ok = 3.402823466e38
        expect_out_of_range { Float32.new(lower_not_ok) }
        expect_out_of_range { Float32.new(upper_not_ok) }
      end
    end

    describe "Float64" do
      it "can be instantiated, packed and unpacked" do
        [ -123.456, 3001.4001, 42.424242 ].each do |num|
          obj = Float64.new(num)
          obj.to_ruby.should == num
          str = obj.pack
          str.length.should == 8
          Float64.unpack(str).to_ruby.should be_within(0.0001).of(num)
        end
      end

      it "handles more extreme values than Float32" do
        small_ok = -3.402823466e38
        big_ok = 3.402823466e38
        Float64.new(small_ok) # should be ok
        Float64.new(big_ok) # should be ok
      end
    end

  end # describe Built-ins
end # Cauterize module
