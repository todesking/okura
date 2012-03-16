module Okura
  module WordDic
    class Naive
      def initialize
        @size=0
        @root=TrieNode.new
      end
      class TrieNode
        def initialize
          @nodes={}
          @leafs=[]
        end
        def add word,i=0
          if i==word.surface.length
            @leafs.push word
          else
            fst=word.surface[i]
            node=@nodes[fst]
            @nodes[fst]=node=TrieNode.new if node.nil?
            node.add word,i+1
          end
        end
        def find_all str,i,res=Array.new
          res.concat @leafs
          return res unless i < str.length
          node=@nodes[str[i]]
          return res if node.nil?
          node.find_all(str,i+1,res)
          res
        end
      end
      attr_reader :size
      def define word
        @size+=1
        @root.add word
      end
      # -> [Word]
      def possible_words str,i
        @root.find_all str,i
      end
      def word_size
        @size
      end
    end
    class DoubleArray
      def initialize words,base,check
        @words,@base,@check=words,base,check
      end
      def possible_words str,i
        ret=[]
        prev=nil
        cur=0
        str[i..-1].bytes.each{|c|
          next_index=@base[cur]+c+1
          break unless @check[next_index]==cur
          prev,cur=cur,next_index
          # check EOS node
          eos_index=@base[cur]
          if @check[eos_index]==cur
            raise "@base[#{eos_index}] should < 0 but #{@base[eos_index]}" unless @base[eos_index] < 0
            ret.push -@base[eos_index]-1
          end
        }
        return ret.map{|x|@words[x]}
      end
      def word_size
        @words.size
      end
      class Builder
        class DAData
          def initialize root
            @base=[]
            @check=[nil]
            @used=[true]
            construct root
          end
          attr_reader :base
          attr_reader :check

          private
          def construct node
            s=alloc 0,node
            @base[0]=s
            return s
          end
          def alloc parent,node
            s=nil
            length.times{|i|
              if (!node.has_data? || !@used[i]) && node.children.keys.none?{|c|@used[i+c+1]}
                s=i
                break
              end
            }
            s=self.length if s.nil?

            @used[s]=true if node.has_data?
            node.children.keys.each{|c|
              @used[s+c+1]=true
            }

            if node.has_data?
              idx=s+0
              assert @used[idx]
              @base[idx]=-node.data-1
              @check[idx]=parent
            end
            node.children.each{|c,cn|
              assert 0<=c
              idx=s+c+1
              assert @used[idx]
              cs=alloc idx,cn
              @base[idx]=cs
              @check[idx]=parent
            }
            s
          end
          def length
            [@base,@check,@used].map(&:length).max
          end
          def to_s indent=0,parent=0
            ret="#{' '*indent}+ #{parent}"
            length.times{|i|
              if @check[i]==parent
                ret+="\n#{' '*indent}  base=#{base[i]}"
                ret+="\n"+to_s(indent+2,i)
              end
            }
            ret
          end
          def assert cond
            raise 'assertion error' unless cond
          end
        end
        class Node
          def initialize
            @children={}
            @data=nil
          end
          def has_data?; !@data.nil?; end
          attr_reader :children
          attr_reader :data
          def add key,i,data
            if key.length==i
              @data=data
            else
              child_node=( @children[key[i]]||=Node.new )
              child_node.add key,i+1,data
            end
          end
        end
        def initialize
          @root=Node.new
          @words=[]
        end
        def define word
          wid=@words.length
          @words.push word
          key=word.surface.bytes.to_a
          @root.add key,0,wid
        end
        def build
          da=DAData.new @root
          DoubleArray.new @words,da.base,da.check
        end
        # -> [ Marshal [Word], [Integer], [Integer] ]
        def data_for_serialize
          da=DAData.new @root
          [@words,da.base,da.check]
        end
        # [ Marshal [Word], [Integer], [Integer] ] -> WordDic::DoubleArray
        def self.build_from_serialized data
          words,base,check=data
          DoubleArray.new words,base,check
        end
      end
    end
  end
end
