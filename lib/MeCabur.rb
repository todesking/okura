# coding: utf-8
def todo
  $stderr.puts "TODO at #{caller[1]}"
end


module MeCabur
  class Tagger
    todo
    def initialize
      @dic=todo
    end
    def wakati str
      parse(str).mincost_path.map{|node|node.word.surface}
    end
    def parse str
      chars=str.split(//)
      nodes=Nodes.new(chars.length+2)
      nodes.add(0,mk_bos())
      nodes.add(chars.length+1,mk_eos)
      str.length.times{|i|
        @dic.possible_words(str,i).each{|w|
          nodes.add(i+1,mk_node(w))
        }
      }
      nodes
    end
    private
    def mk_eos
      todo
    end
    def mk_bos
      todo
    end
    def mk_node
    end
  end
  class Nodes
    todo
  end
  class Node
    attr_reader :word
  end
  class Word
    attr_reader :surface
  end
  class Dic
    todo
    def possible_words str,i
      todo
    end
  end
  class Matrix
    todo
  end
end
