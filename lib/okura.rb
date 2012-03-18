# coding: utf-8
require 'okura/word_dic'

module Okura
  class Tagger
    def initialize dic,mat
      @dic,@mat=dic,mat
    end
    attr_reader :dic
    attr_reader :mat
    # -> [String]
    def wakati str,mat
      mincost_path=parse(str).mincost_path
      return nil if mincost_path.nil?
      return mincost_path.map{|node|node.word.surface}
    end
    # -> Nodes
    def parse str
      chars=str.split(//)
      nodes=Nodes.new(chars.length+2,@mat)
      nodes.add(0,Node.mk_bos_eos)
      nodes.add(chars.length+1,Node.mk_bos_eos)
      str.length.times{|i|
        @dic.possible_words(str,i).each{|w|
          nodes.add(i+1,Node.new(w))
        }
      }
      nodes
    end
  end
  class Nodes
    def initialize len,mat
      @mat=mat
      @begins=(0...len).map{[]}
      @ends=(0...len).map{[]}
    end
    def [](i)
      @begins[i]
    end
    def length
      @begins.length
    end
    # Matrix -> [Node] | nil
    def mincost_path
      return [] if length==0
      # calc cost
      self[0].each{|n|
        n.total_cost=n.word.cost
        n.nearest_prev=nil
      }
      (1...length).each{|i|
        prevs=@ends[i-1]
        curs=@begins[i]
        prevs.each{|prev|
          # 途中で行き止まりのNodeはtotal_costが設定されない
          next if prev.total_cost.nil?
          curs.each{|cur|
            join_cost=@mat.cost(prev.word.right.id,cur.word.left.id)
            next if join_cost.nil?
            cost=prev.total_cost+join_cost+cur.word.cost
            if !cur.total_cost || cost < cur.total_cost
              cur.total_cost=cost
              cur.nearest_prev=prev
            end
          }
        }
      }
      # calc mincost path
      ret=[]
      cur=self[-1][0]
      until cur.nil?
        ret.push cur
        cur=cur.nearest_prev
      end
      # TODO: disconnected
      #  return nil unless ...
      # success
      return ret.reverse
    end
    def add i,node
      @begins[i].push node
      @ends[i+node.length-1].push node
    end
  end
  class Node
    def initialize word
      @word=word
      @nearest_prev=nil
      @total_cost=nil
    end
    attr_reader :word
    attr_accessor :nearest_prev
    attr_accessor :total_cost
    def length
      word.surface.length
    end
    def to_s
      "Node(#{word},#{total_cost})"
    end
    def self.mk_bos_eos
      f=Features::BOS_EOS
      node=Node.new Word.new('BOS/EOS',f,f,0)
      def node.length; 1; end
      node
    end
  end
  class Words
    def initialize
      # group id -> [Word]
      @groups={}
      @next_group_id=0
      # surface -> id
      @group_ids={}
    end
    def add word
      unless @group_ids.has_key? word.surface
        gid=@next_group_id
        @next_group_id+=1
        @group_ids[word.surface]=gid
        @groups[gid]=[word]
        gid
      else
        gid=@group_ids[word.surface]
        @groups[gid].push word
        gid
      end
    end
    def group group_id
      @groups[group_id]
    end
    def word_size
      @groups.values.inject(0){|a,x|a+x.size}
    end
  end
  class Word
    def initialize surface,left,right,cost
      raise unless left.respond_to? :text
      @surface,@left,@right,@cost=surface,left,right,cost
    end
    # String
    attr_reader :surface
    # Feature
    attr_reader :left
    # Feature
    attr_reader :right
    # Integer
    attr_reader :cost
    def == other
      return [surface,left,right,cost] ==
        [other.surface,other.left,other.right,other.cost]
    end
    def hash
      [surface,left,right,cost].hash
    end
    def to_s
      "Word(#{surface},#{left.id},#{right.id},#{cost})"
    end
  end
  class Feature
    def initialize id,text
      @id,@text=id,text
    end
    attr_reader :id
    attr_reader :text
    def to_s
      "Feature(#{id},#{text})"
    end
    def == other
      return self.id==other.id
    end
    def hash
      self.id.hash
    end
  end
  class Features
    def initialize
      @map_id={}
    end
    # Integer -> Feature
    def from_id id
      @map_id[id]
    end
    def add id,text
      @map_id[id]=Feature.new id,text
    end
    def size
      @map_id.size
    end
    BOS_EOS=Feature.new 0,'BOS/EOS'
  end
  class Dic
    def initialize word_dic,unk_dic
      @word_dic,@unk_dic=word_dic,unk_dic
    end
    attr_reader :word_dic
    attr_reader :unk_dic
    # -> [Word]
    def possible_words str,i
      ret=@word_dic.possible_words str,i
      ret.concat(@unk_dic.possible_words(str,i,!ret.empty?))
      ret
    end
  end
  class UnkDic
    # CharTypes -> Features ->
    def initialize char_types
      @char_types=char_types
      # CharType.name => [Word]
      @templates={}
    end
    # -> [Word]
    def possible_words str,i,found_in_normal_dic
      ret=[]
      first_char_type=@char_types.type_for str[i].ord
      return [] if found_in_normal_dic && !first_char_type.invoke?

      collect_result ret,first_char_type,str[i..i] if first_char_type.length > 0

      l=1
      str[(i+1)..-1].each_codepoint{|cp|
        break unless first_char_type.accept? cp
        l+=1
        collect_result ret,first_char_type,str[i...(i+l)] if first_char_type.length >= l
      }
      collect_result ret,first_char_type,str[i...(i+l)] if first_char_type.group? && first_char_type.length < l

      ret
    end
    private
    def collect_result ret,type,surface
      (@templates[type.name]||[]).each{|tp|
        ret.push Word.new surface,tp.left,tp.right,tp.cost
      }
    end
    public
    # String -> Feature -> Feature -> Integer ->
    def define type_name,left,right,cost
      type=@char_types.named type_name
      (@templates[type_name]||=[]).push Word.new '',left,right,cost
    end
    def word_templates_for type_name
      @templates[type_name].dup
    end
    def rule_size
      @templates.values.inject(0){|sum,t|sum+t.size}
    end
  end
  class CharTypes
    def initialize
      @types={}
      @mapping={}
      @compat_mapping={}
    end
    def type_for charcode
      @mapping[charcode]||default_type||
        (raise "Char type for 0x#{charcode.to_s(16)} is not defined,"+
         " and DEFAULT type is not defined too")
    end
    def define_type name,invoke,group,length
      @types[name]=CharType.new(name,invoke,group,length)
    end
    def define_map charcode,type,compat_types
      @mapping[charcode]=type
      type.add charcode
      compat_types.each{|ct|ct.add charcode}
    end
    def named name
      @types[name] || (raise "Undefined char type: #{name}")
    end
    def default_type
      named 'DEFAULT'
    end
  end
  class CharType
    def initialize name,invoke,group,length
      @name,@invoke,@group,@length=name,invoke,group,length
      @accept_charcodes={}
    end
    def add charcode
      @accept_charcodes[charcode]=true
    end
    attr_reader :name
    attr_reader :length
    def group?; @group; end
    def invoke?; @invoke; end
    def accept? charcode
      @accept_charcodes[charcode]
    end
  end
  class Matrix
    def initialize rsize,lsize
      @mat=[nil]*(lsize*rsize)
      @lsize,@rsize=lsize,rsize
    end
    # Feature.id -> Feature.id -> Int
    def cost rid,lid
      @mat[rid*lsize+lid]
    end
    def set(rid,lid,cost)
      @mat[rid*lsize+lid]=cost
    end
    attr_reader :rsize
    attr_reader :lsize
  end
end
