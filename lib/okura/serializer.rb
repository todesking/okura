module Okura
  module Serializer
    class FormatInfo
      # todo
    end
    module WordDic
      class Naive
        def compile(features,input,output)
          parser=Okura::Parser::Word.new(input)
          dic=Okura::WordDic::Naive.new
          parser.each{|surface,lid,rid,cost|
            word=Okura::Word.new(
              surface,
              features.from_id(lid),
              features.from_id(rid),
              cost
            )
            dic.define word
          }
          Marshal.dump(dic,output)
        end
        def load(io)
          Marshal.load(io)
        end
      end
      class DoubleArray
        def compile(features,input,output)
          parser=Okura::Parser::Word.new(input)
          dic=Okura::WordDic::DoubleArray::Builder.new
          parser.each{|surface,lid,rid,cost|
            word=Okura::Word.new(
              surface,
              features.from_id(lid),
              features.from_id(rid),
              cost
            )
            dic.define word
          }
          data=dic.data_for_serialize
          Marshal.dump(data,output)
        end
        def load(io)
          data=Marshal.load(io)
          Okura::WordDic::DoubleArray::Builder.build_from_serialized data
        end
      end
    end
  end
end
