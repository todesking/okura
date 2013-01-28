# -*- coding: utf-8 -*-

require 'yaml'
require 'okura'
require 'okura/parser'

module Okura
  module Serializer
    # 辞書ファイルのコンパイル形式を表現し､コンパイルとロードの制御を担当する
    class FormatInfo
      def initialize
        @word_dic=:DoubleArray
        @unk_dic=:Marshal
        @features=:Marshal
        @char_types=:Marshal
        @matrix=:Marshal
      end

      attr_accessor :word_dic
      attr_accessor :unk_dic
      attr_accessor :features
      attr_accessor :char_types
      attr_accessor :matrix

      # 指定されたディレクトリにあるソースをコンパイルする
      def compile_dict src_dir,bin_dir
        open_dest(bin_dir,'format-info'){|dest| self.compile dest}
        features_l=open_src(src_dir,'left-id.def'){|src|
          open_dest(bin_dir,'left-id.bin'){|dest|
            serializer_for('Features',features).compile(src,dest)
          }
        }

        features_r=open_src(src_dir,'right-id.def'){|src|
          open_dest(bin_dir,'right-id.bin'){|dest|
            serializer_for('Features',features).compile(src,dest)
          }
        }

        word_src_files=
          Dir.chdir(src_dir){ Dir.glob('*.csv') }.
          map{|file|File.join(src_dir,file)}
        open_dest(bin_dir,'word_dic.bin'){|dest|
          serializer_for('WordDic',word_dic).compile(features_l,features_r,word_src_files,dest)
        }

        char_types=open_src(src_dir,'char.def'){|src|
          open_dest(bin_dir,'char_types.bin'){|dest|
            serializer_for('CharTypes',@char_types).compile(src,dest)
          }
        }

        open_src(src_dir,'unk.def'){|src|
          open_dest(bin_dir,'unk_dic.bin'){|dest|
            serializer_for('UnkDic',unk_dic).compile(char_types,features_l,features_r,src,dest)
          }
        }

        open_src(src_dir,'matrix.def'){|src|
          open_dest(bin_dir,'matrix.bin'){|dest|
            serializer_for('Matrix',matrix).compile(src,dest)
          }
        }
      end

      # 指定されたディレクトリにあるコンパイル済み辞書をロードし､Taggerを作成する
      def self.create_tagger bin_dir
        format_info=File.open(File.join(bin_dir,'format-info')){|f| self.load f }
        format_info.create_tagger bin_dir
      end

      def create_tagger bin_dir
        features_l=open_bin(bin_dir,'left-id.bin'){|bin|
          serializer_for('Features',features).load(bin)
        }
        features_r=open_bin(bin_dir,'right-id.bin'){|bin|
          serializer_for('Features',features).load(bin)
        }
        wd=open_bin(bin_dir,'word_dic.bin'){|f|
          serializer_for('WordDic',word_dic).load(f)
        }
        ud=open_bin(bin_dir,'unk_dic.bin'){|f|
          serializer_for('UnkDic',unk_dic).load(f)
        }
        mat=open_bin(bin_dir,'matrix.bin'){|f|
          serializer_for('Matrix',matrix).load(f)
        }
        dic=Okura::Dic.new wd,ud
        tagger=Okura::Tagger.new dic,mat
        tagger
      end

      # このFormatInfoオブジェクトをシリアライズする
      def compile io
        YAML.dump({
          word_dic: word_dic,
          unk_dic: unk_dic,
          features: features,
          char_types: char_types,
          matrix: matrix
        },io)
      end

      # シリアライズされたFormatInfoオブジェクトを復元する
      def self.load io
        data=YAML.load(io)
        fi=FormatInfo.new
        fi.word_dic=data[:word_dic]
        fi.unk_dic=data[:unk_dic]
        fi.features=data[:features]
        fi.char_types=data[:char_types]
        fi.matrix=data[:matrix]
        fi
      end

      private

      def open_src dir,filename,&block
        File.open(File.join(dir,filename),&block)
      end

      def open_dest dir,filename,&block
        File.open(File.join(dir,filename),'wb:ASCII-8BIT',&block)
      end

      def open_bin dir,filename,&block
        File.open(File.join(dir,filename),'rb:ASCII-8BIT',&block)
      end

      def serializer_for data_type_name,format_type_name
        data_type=Okura::Serializer.const_get data_type_name
        format_type=data_type.const_get format_type_name
        format_type.new
      end
    end

    module Features
      class Marshal
        def compile(input,output)
          parser=Okura::Parser::Feature.new input
          features=Okura::Features.new
          parser.each{|id,text|
            features.add id,text
          }
          ::Marshal.dump(features,output)
          features
        end

        def load(io)
          ::Marshal.load(io)
        end
      end
    end

    module WordDic
      def self.each_input inputs,&block
        inputs.each{|input|
          case input
          when String
            File.open(input,&block)
          else
            block.call input
          end
        }
      end

      class Naive
        def compile(features_l,features_r,inputs,output)
          dic=Okura::WordDic::Naive.new
          Okura::Serializer::WordDic.each_input(inputs){|input|
            parser=Okura::Parser::Word.new(input)
            parser.each{|surface,lid,rid,cost|
              word=Okura::Word.new(
                surface,
                features_l.from_id(lid),
                features_r.from_id(rid),
                cost
              )
              dic.define word
            }
          }
          Marshal.dump(dic,output)
        end

        def load(io)
          Marshal.load(io)
        end
      end

      class DoubleArray
        def compile(features_l,features_r,inputs,output)
          puts 'loading...'
          dic=Okura::WordDic::DoubleArray::Builder.new
          Okura::Serializer::WordDic.each_input(inputs){|input|
            parser=Okura::Parser::Word.new(input)
            parser.each{|surface,lid,rid,cost|
              word=Okura::Word.new(
                surface,
                features_l.from_id(lid),
                features_r.from_id(rid),
                cost
              )
              dic.define word
            }
          }

          writer=Okura::Serializer::BinaryWriter.new output
          words,base,check=dic.data_for_serialize
          raise 'base.length!=check.length' if base.length!=check.length
          puts 'writing words...'
          words.instance_eval do
            writer.write_object @groups
            writer.write_object @left_features
            writer.write_object @right_features
            writer.write_int32_array @left_ids
            writer.write_int32_array @right_ids
            writer.write_int32_array @costs
            writer.write_int32_array @surface_ids
            @surfaces.instance_eval do
              writer.write_object @str
              writer.write_int32_array @indices
            end
          end
          puts 'writing word index...'
          writer.write_int32_array base
          writer.write_int32_array check
        end

        def load(io)
          reader=Okura::Serializer::BinaryReader.new io
          words=begin
                  groups=reader.read_object
                  left_features=reader.read_object
                  right_features=reader.read_object
                  left_ids=reader.read_int32_array
                  right_ids=reader.read_int32_array
                  costs=reader.read_int32_array
                  surface_ids=reader.read_int32_array
                  surfaces=begin
                             str=reader.read_object
                             indices=reader.read_int32_array
                             Okura::Words::CompactStringArray.new str,indices
                           end
                  Okura::Words.new(
                    groups,surfaces,left_features,right_features,surface_ids,left_ids,right_ids,costs
                  )
                end
          base=reader.read_int32_array
          check=reader.read_int32_array
          Okura::WordDic::DoubleArray::Builder.build_from_serialized [words,base,check]
        end
      end
    end

    module CharTypes
      class Marshal
        def compile(input,output)
          cts=Okura::CharTypes.new

          parser=Okura::Parser::CharType.new
          parser.on_chartype_def{|name,invoke,group,length|
            cts.define_type(name,invoke,group,length)
          }
          parser.on_mapping_single{|char,type,ctypes|
            cts.define_map char,cts.named(type),ctypes.map{|ct|cts.named(ct)}
          }
          parser.on_mapping_range{|from,to,type,ctypes|
            (from..to).each{|char|
              cts.define_map char,cts.named(type),ctypes.map{|ct|cts.named(ct)}
            }
          }
          parser.parse_all input

          ::Marshal.dump(cts,output)
          cts
        end

        def load(io)
          ::Marshal.load(io)
        end
      end
    end

    module UnkDic
      class Marshal
        def compile(char_types,features_l,features_r,input,output)
          unk=Okura::UnkDic.new char_types
          parser=Okura::Parser::UnkDic.new input
          parser.each{|type_name,lid,rid,cost|
            unk.define type_name,features_l.from_id(lid),features_r.from_id(rid),cost
          }
          ::Marshal.dump(unk,output)
        end

        def load(io)
          ::Marshal.load(io)
        end
      end
    end

    module Matrix
      class Marshal
        def compile(input,output)
          parser=Okura::Parser::Matrix.new input
          mat=Okura::Matrix.new parser.rid_size,parser.lid_size
          parser.each{|rid,lid,cost|
            mat.set(rid,lid,cost)
          }
          ::Marshal.dump(mat,output)
        end

        def load(io)
          ::Marshal.load(io)
        end
      end
    end

    class BinaryReader
      def initialize io
        @io=io
      end

      def read_int32
        @io.read(4).unpack('l').first
      end

      def read_int32_array
        size=read_int32
        @io.read(4*size).unpack('l*')
      end

      def read_object
        Marshal.load @io
      end
    end

    class BinaryWriter
      def initialize io
        @io=io
      end

      def write_int32 value
        @io.write [value].pack('l')
      end

      def write_int32_array value
        write_int32 value.length
        @io.write value.pack('l*')
      end

      def write_object obj
        Marshal.dump obj,@io
      end
    end
  end
end
