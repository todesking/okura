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
  end
end
