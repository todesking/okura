require 'okura'
require 'okura/parser'

module Okura
  module Loader
    # MeCab形式のプレインテキスト用
    class MeCab
      # dict_dirのデータからTaggerを構築する
      def load dict_dir
        rights=load_dict_file(dict_dir,'right-id.def'){|f|
          load_features f
        }

        lefts=load_dict_file(dict_dir,'left-id.def'){|f|
          load_features f
        }

        char_types=load_dict_file(dict_dir,'char.def'){|f|
          load_char_types f
        }

        unk_dic=load_dict_file(dict_dir,'unk.def'){|f|
          load_unk_dic f,char_types,lefts,rights
        }

        word_dic=load_dict_file(dict_dir,'naist-jdic.csv'){|f|
          load_words f,lefts,rights
        }

        mat=load_dict_file(dict_dir,'matrix.def'){|f|
          load_matrix f
        }

        dic=Okura::Dic.new(word_dic,unk_dic)

        tagger=Okura::Tagger.new dic,mat

        tagger
      end
      private
      def load_dict_file dict_dir,name
        open(File.join(dict_dir,name)){|f|
          yield f
        }
      end
      public

      def load_matrix io
        parser=Okura::Parser::Matrix.new io
        mat=Matrix.new parser.rid_size,parser.lid_size
        parser.each{|rid,lid,cost|
          mat.set(rid,lid,cost)
        }
        mat
      end
      def load_words io,lefts,rights
        wd=Okura::WordDic::Naive.new
        parser=Okura::Parser::Word.new io
        parser.each{|surface,lid,rid,cost|
          lid,rid,cost=[lid_s,rid_s,cost_s].map(&:to_i)
          wd.define Word.new(surface,lefts.from_id(lid),rights.from_id(rid),cost)
        }
        wd
      end
      def load_features io
        fs=Features.new
        io.each_line{|line|
          id_s,name=line.strip.split(/ /,2)
          id=id_s.to_i
          fs.add id,name
        }
        fs
      end
      def load_char_types io
        cts=CharTypes.new
        io.each_line{|line|
          cols=line.gsub(/\s*#.*$/,'').split(/\s+/)
          next if cols.empty?

          case cols[0]
          when /^0x([0-9a-fA-F]{4})(?:\.\.0x([0-9a-fA-F]{4}))?$/
            # mapping
            parse_error line unless cols.size >= 2
            type=cts.named cols[1]
            compat_types=cols[2..-1].map{|name|cts.named name}
            if $2
              ($1.to_i(16)..$2.to_i(16)).each{|c|
                cts.define_map(c,type,compat_types)
              }
            else
              cts.define_map($1.to_i(16),type,compat_types)
            end
          when /^\w+$/
            parse_error line unless cols.size == 4
            # typedef
            cts.define_type cols[0],(cols[1]=='1'),(cols[2]=='1'),Integer(cols[3])
          else
            # error
            parse_error line
          end
        }
        cts
      end
      def load_unk_dic io,char_types,lefts,rights
        udic=UnkDic.new char_types
        io.each_line {|line|
          type_s,lid_s,rid_s,cost_s,additional=line.split(/,/,5)
          lid,rid,cost=[lid_s,rid_s,cost_s].map(&:to_i)
          udic.define type_s,lefts.from_id(lid),rights.from_id(rid),cost
        }
        udic
      end
      private
      def parse_error line
        raise "Illegal format: #{line}"
      end
    end
    class Marshal
      def load dict_dir
        open(File.join(dict_dir,'okura.bin')){|f| ::Marshal.load f }
      end
    end
  end
end
