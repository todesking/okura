# -*- coding: utf-8 -*-

module Okura
  module Parser

    def parse_error line
      raise 'parse error: '+line
    end

    module Base
      def initialize io
        @io=io
      end

      include Enumerable

      def each &b
        return Enumerator.new(self) unless b

        @io.each_line {|line|
          b.call *parse(line)
        }
      end
    end

    class Matrix
      include Base

      def initialize io
        @io=io
        @rid_size,@lid_size=io.readline.split(/\s/).map(&:to_i)
      end

      attr_reader :rid_size
      attr_reader :lid_size

      def parse line
        rid,lid,cost=line.split(/\s/).map(&:to_i)
        [rid,lid,cost]
      end
    end

    class Word
      include Base
      def parse line
        ti,ts=:to_i,:to_s
        cols=line.split /,/
        cols[0..3].zip([ts,ti,ti,ti]).map{|v,f|f.to_proc.call v}
      end
    end

    class Feature
      include Base
      def parse line
        id_s,name=line.strip.split(/ /,2)
        id=id_s.to_i
        [id,name]
      end
    end

    class UnkDic
      include Base
      def parse line
        type_s,lid_s,rid_s,cost_s,additional=line.split(/,/,5)
        lid,rid,cost=[lid_s,rid_s,cost_s].map(&:to_i)
        [type_s,lid,rid,cost]
      end
    end

    class CharType
      def initialize
        @callbacks={
          :mapping_single=>[],
          :mapping_range=>[],
          :define_type=>[]
        }
      end

      def on_mapping_single &b
        @callbacks[:mapping_single] << b
      end

      def on_mapping_range &b
        @callbacks[:mapping_range] << b
      end

      def on_chartype_def &b
        @callbacks[:define_type] << b
      end

      def parse_all io
        io.each_line {|line|
          parse line
        }
      end

      def parse line
        cols=line.gsub(/\s*#.*$/,'').split(/\s+/)
        return if cols.empty?

        case cols[0]
        when /^0x([0-9a-fA-F]{4})(?:\.\.0x([0-9a-fA-F]{4}))?$/
          # mapping
          parse_error line unless cols.size >= 2
          type=cols[1]
          compat_types=cols[2..-1]
          from=$1.to_i(16)
          if $2
            # mapping(range)
            to=$2.to_i(16)
            @callbacks[:mapping_range].each{|c|
              c.call from,to,type,compat_types
            }
          else
            # mapping(single)
            @callbacks[:mapping_single].each{|c|
              c.call from,type,compat_types
            }
          end
        when /^\w+$/
          parse_error line unless cols.size == 4
          # typedef
          @callbacks[:define_type].each{|c|
            c.call cols[0],(cols[1]=='1'),(cols[2]=='1'),Integer(cols[3])
          }
        else
          # error
          parse_error line
        end
      end
    end
  end
end
