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
    # -> [String]
    def wakati str
      parse(str).mincost_path.map{|node|node.word.surface}
    end
    # -> Nodes
    def parse str
      chars=str.split(//)
      nodes=Nodes.new(chars.length+2)
      nodes.add(0,Node.mk_bos)
      nodes.add(chars.length,Node.mk_eos)
      str.length.times{|i|
        @dic.possible_words(str,i).each{|w|
          nodes.add(i,w)
        }
      }
      nodes
    end
  end
  class Nodes
    def initialize len
      @begins=todo
      @ends=todo
    end
    todo
    def last
      self[-1]
    end
    def [](i)
      @begins[i]
    end
    def mincost_path
      last.each{|eos|
      }
      todo
    end
    def add i,word
      todo
    end
  end
  class Node
    attr_reader :word
    def mk_eos
      todo
    end
    def mk_bos
      todo
    end
    def mk_node
      todo
    end
  end
  class Word
    attr_reader :surface
  end
  class Dic
    todo
    # -> [Word]
    def possible_words str,i
      @wdic.lookup(str,i)+@udic.possible_words(str,i)
    end
  end
  class WordDic
    # -> [Word]
    def possible_words str,i
      todo
    end
    todo
  end
  class UnkDic
    # -> [Word]
    def possible_words str,i
      todo
    end
    todo
  end
  class Matrix
    todo
  end
end
