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
    end
  end
end
