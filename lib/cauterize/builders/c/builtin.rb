module Cauterize
  module Builders
    module C
      class BuiltIn < Buildable
        @@C_TYPE_MAPPING = {
          1 => {signed:  :int8_t, unsigned:  :uint8_t},
          2 => {signed: :int16_t, unsigned: :uint16_t},
          4 => {signed: :int32_t, unsigned: :uint32_t},
          8 => {signed: :int64_t, unsigned: :uint64_t},
        }

        def render
          render_ctype
        end

        def declare(formatter, sym)
          formatter << "#{render} #{sym};"
        end

        # These are identical to the Scalar definitions. For now.
        def packer_defn(formatter)
          formatter << packer_sig
          formatter.braces do
            formatter << "return CauterizeAppend(dst, (uint8_t*)src, sizeof(*src));"
          end
        end

        def unpacker_defn(formatter)
          formatter << unpacker_sig
          formatter.braces do
            formatter << "return CauterizeRead(src, (uint8_t*)dst, sizeof(*dst));"
          end
        end

        private

        def render_ctype
          s_key = @blueprint.is_signed ? :signed : :unsigned
          @@C_TYPE_MAPPING[@blueprint.byte_length][s_key]
        end
      end
    end
  end
end

Cauterize::Builders.register(:c, Cauterize::BuiltIn, Cauterize::Builders::C::BuiltIn)
