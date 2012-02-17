module Okura
  module Parser
    class Matrix

      include Enumerable

      def initialize io
        @io=io
        @rid_size,@lid_size=io.readline.split(/\s/).map(&:to_i)
      end

      attr_reader :rid_size
      attr_reader :lid_size

      def each &b
        return Enumerator.new(self) unless b

        @io.each_line {|line|
          rid,lid,cost=line.split(/\s/).map(&:to_i)
          b.call rid,lid,cost
        }
      end

    end

    class Word

      include Enumerable

      def initialize io
        @io=io
      end

      def each &b
        return Enumerator.new(self) unless b

        ti=:to_i
        ts=:to_s
        @io.each_line {|line|
          cols=line.split /,/
          b.call cols[0..3].zip([ts,ti,ti,ti]).map{|v,f|f.to_proc.call v}
        }
      end

    end
  end
end
