# -*- coding: utf-8 -*-

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
      # Words -> [Integer] -> [Integer]
      def initialize words,base,check
        @words,@base,@check=words,base,check
      end

      def possible_words str,i
        ret=[]
        prev=nil
        cur=1
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
        return ret.map{|x|@words.group(x)}.flatten(1)
      end

      def word_size
        @words.word_size
      end

      class Builder
        class DAData
          def initialize root
            # offset | +0         | +1       | +2       | ...
            # data   | -data_id-1 | child(0) | child(1) | ...
            #
            # base[0] = -last free cell
            # check[0] = -first free cell
            # 1 = root node id
            @base=[0,0]
            @check=[0,0]
            @length=2
            b,node_id=construct! root
            @base[1]=b
          end

          attr_reader :base
          attr_reader :check
          attr_reader :length

          def construct! node,parent=1
            # base[parent_node_id] should == s
            # -base[s+0] : data id
            # s+1+c : child node id for char c
            # check[m] : parent node id for node m
            s=find_free_space_for node
            if node.has_data?
              alloc! s,parent
              @base[s]=-node.data_id-1
            end
            node.children.each{|c,cn| alloc! child_index(s,c),parent }
            node.children.each{|c,cn|
              idx=child_index(s,c)
              @base[idx]=construct! cn,idx
            }
            s
          end

          def child_index base,c
            base+c+1
          end

          def alloc! index,parent
            assert index>0
            assert free?(index)
            if length <= index
              expand!(index+1)
            end
            assert has_free_cell?

            prev_free=-@base[index]
            next_free=-@check[index]
            @base[next_free]=-prev_free
            @check[prev_free]=-next_free
            @base[index]=0 # dummy value
            @check[index]=parent
            assert !free?(index)
          end

          def expand! size
            if size <= length
              return
            end
            (length...size).each{|i|
              if has_free_cell?
                @base[i]=@base[0]
                @check[i]=0
                @check[-@base[0]]=-i
                @base[0]=-i
              else
                @base[i]=0
                @check[i]=0
                @base[0]=-i
                @check[0]=-i
              end
            }
            @length=size
          end

          def free? index
            length <= index || @check[index] <= 0
          end

          def find_free_space_for node
            alloc_indexes=node.children.keys.map{|c|c+1}
            alloc_indexes+=[0] if node.has_data?
            return 0 if alloc_indexes.empty?
            min=alloc_indexes.min
            i=-@check[0]
            while i!=0
              assert free?(i)
              if 0 < i-min && alloc_indexes.all?{|idx|free?(idx+i-min)}
                return i-min
              end
              i=-@check[i]
            end
            # free space not found
            return [length-min,1].max
          end

          def has_free_cell?
            @base[0]!=0
          end

          def assert cond
            raise unless cond
          end
        end

        class Node
          def initialize
            @data_id=nil
            @children={}
          end

          attr_reader :data_id
          attr_reader :children

          def has_data?
            !!data_id
          end

          def add bytes,idx,data_id
            if idx==bytes.length
              @data_id=data_id
            else
              c=bytes[idx]
              (@children[c]||=Node.new).add(bytes,idx+1,data_id)
            end
          end
        end

        def initialize
          @root=Node.new
          @words=Okura::Words::Builder.new
        end

        def define word
          word_group_id=@words.add word
          key=word.surface.bytes.to_a
          @root.add key,0,word_group_id
        end

        def build
          da=DAData.new @root
          DoubleArray.new *data_for_serialize
        end

        # -> [ Words, [Integer], [Integer] ]
        def data_for_serialize
          da=DAData.new @root
          [@words.build,da.base,da.check]
        end

        # [ Words, [Integer], [Integer] ] -> WordDic::DoubleArray
        def self.build_from_serialized data
          words,base,check=data
          puts base.length
          DoubleArray.new words,base,check
        end
      end
    end
  end
end
