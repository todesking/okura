#-*- coding:utf-8
require File.join(File.dirname(__FILE__),'spec_helper.rb')
require File.join(File.dirname(__FILE__),'..','lib','okura')
require File.join(File.dirname(__FILE__),'..','lib','okura','parser')
require File.join(File.dirname(__FILE__),'..','lib','okura','serializer')

require 'tmpdir'

def with_dict_dir &block
  Dir.mktmpdir {|src_dir|
    Dir.mktmpdir {|bin_dir|
      yield src_dir,bin_dir
    }
  }
end

def set_content(dir,filename,content)
  File.open(File.join(dir,filename),'w'){|file|
    file.write content
  }
end

def as_io str
  StringIO.new str
end
def w surface,l,r,cost
  l=f(l) unless l.respond_to? :id
  r=f(r) unless r.respond_to? :id
  Okura::Word.new surface,l,r,cost
end
def f id,name="F#{id}"
  Okura::Feature.new id,name
end
def n *args
  Okura::Node.new *args
end

describe Okura::Parser do
  describe 'Matrix' do
    it 'MeCab形式のMatrixファイルを読める' do
      parser=Okura::Parser::Matrix.new as_io(<<-EOS)
2 3
0 0 0
0 1 1
1 0 2
1 1 3
1 2 10
      EOS
      parser.rid_size.should == 2
      parser.lid_size.should == 3
      parser.each.to_a.should == [
        [0,0,0],
        [0,1,1],
        [1,0,2],
        [1,1,3],
        [1,2,10]
      ]
    end
  end
  describe 'Word' do
    it 'MeCab形式の単語ファイルを読める' do
      parser=Okura::Parser::Word.new as_io(<<-EOS)
あがなう,854,458,6636,動詞,自立,*,*,五段・ワ行促音便,基本形,あがなう,アガナウ,アガナウ,あがなう/購う/贖う,
あがめる,645,546,1234,動詞,自立,*,*,一段,基本形,あがめる,アガメル,アガメル,あがめる/崇める,
      EOS
      parser.each.to_a.map{|x|x[0..3]}.should == [
        ['あがなう',854,458,6636],
        ['あがめる',645,546,1234]
      ]
    end
    it 'ダブルクオートでエスケープされた単語定義も扱える'
  end
  describe 'Feature' do
    it 'MeCab形式の品詞ファイルを読める' do
      parser=Okura::Parser::Feature.new as_io(<<-EOS)
0 BOS/EOS,*,*,*,*,*,BOS/EOS
1 その他,間投,*,*,*,*,*
      EOS
      parser.each.to_a.should == [
        [0,'BOS/EOS,*,*,*,*,*,BOS/EOS'],
        [1,'その他,間投,*,*,*,*,*']
      ]
    end
  end
  describe 'CharType' do
    it 'MeCab形式の文字種定義ファイルを読める' do
      parser=Okura::Parser::CharType.new
      h={single:[],range:[],type:[]}
      parser.on_mapping_single {|code,type,ctypes| h[:single]<<[code,type,ctypes]}
      parser.on_mapping_range{|from,to,type,ctypes| h[:range]<<[from,to,type,ctypes]}
      parser.on_chartype_def{|name,invoke,group,length| h[:type]<<[name,invoke,group,length]}

      parser.parse_all as_io(<<-EOS)
DEFAULT        0 1 0  # DEFAULT is a mandatory category!
KATAKANA       1 0 2

0x000D SPACE  # CR
0x003A..0x0040 SYMBOL
# KANJI
0x5146 KANJINUMERIC KANJI
      EOS

      h[:single].should == [
        [0x000D, 'SPACE', []],
        [0x5146, 'KANJINUMERIC', %w(KANJI)]
      ]
      h[:range].should == [
        [0x003A, 0x0040, 'SYMBOL', []]
      ]
      h[:type].should == [
        ['DEFAULT', false, true, 0],
        ['KATAKANA', true, false, 2]
      ]
    end
  end
  describe 'UnkDic' do
    it '未知語の定義を読める' do
      parser=Okura::Parser::UnkDic.new as_io(<<-EOS)
A,5,6,3274,記号,一般,*,*,*,*,*
Z,9,10,5244,記号,空白,*,*,*,*,*
      EOS
      parser.to_a.should == [
        ['A',5,6,3274],
        ['Z',9,10,5244]
      ]
    end
  end
end

describe 'Compile and load' do
  describe Okura::Serializer::FormatInfo do
    it 'シリアライズして復元できる' do
      info=Okura::Serializer::FormatInfo.new
      info.word_dic=:Naive
      info.features=:Marshal
      info.char_types=:Marshal
      info.unk_dic=:Marshal
      info.matrix=:Marshal

      out=StringIO.new
      info.compile(out)
      out.rewind

      loaded=Okura::Serializer::FormatInfo.load(out)
      loaded.word_dic.should == :Naive
      loaded.features.should == :Marshal
      loaded.char_types.should == :Marshal
      loaded.unk_dic.should == :Marshal
      loaded.matrix.should == :Marshal
    end
    it '設定に基づいて辞書をコンパイル/ロードできる' do
      with_dict_dir{|src_dir,bin_dir|
        set_content(src_dir,'w1.csv',<<-EOS)
w1,1,2,1000,
        EOS
        set_content(src_dir,'w2.csv',<<-EOS)
w2,5,6,2000,
w3,9,10,3000,
        EOS
        set_content(src_dir,'left-id.def',<<-EOS)
1 F1
5 F5
9 F9
        EOS
        set_content(src_dir,'right-id.def',<<-EOS)
2 F2
6 F6
10 F10
        EOS
        set_content(src_dir,'char.def',<<-EOS)
A 0 0 1
Z 1 1 3
        EOS
        set_content(src_dir,'unk.def',<<-EOS)
A,5,6,3274,記号,一般,*,*,*,*,*
Z,9,10,5244,記号,空白,*,*,*,*,*
        EOS
        set_content(src_dir,'matrix.def',<<-EOS)
2 3
0 0 10
0 1 5
        EOS

        fi=Okura::Serializer::FormatInfo.new
        fi.encoding='UTF-8'
        fi.compile_dict(src_dir,bin_dir)

        tagger=Okura::Serializer::FormatInfo.create_tagger(bin_dir)

        tagger.dic.unk_dic.rule_size.should == 2
        tagger.dic.word_dic.word_size.should == 3
        tagger.mat.cost(0,1).should == 5

        w2=tagger.dic.word_dic.possible_words('w2',0)[0]
        w2.left.text.should == 'F5'
        w2.right.text.should == 'F6'
        u1=tagger.dic.unk_dic.word_templates_for('A')[0]
        u1.left.text.should == 'F5'
        u1.right.text.should == 'F6'
      }
    end
  end
  describe Okura::Serializer::Features::Marshal do
    it 'コンパイルして復元できる' do
      serializer=Okura::Serializer::Features::Marshal.new
      out=StringIO.new
      serializer.compile(as_io(<<-EOS),out)
0 BOS/EOS,*,*,*,*,*,BOS/EOS
1 その他,間投,*,*,*,*,*
      EOS
      out.rewind

      features=serializer.load(out)
      features.from_id(0).text.should == 'BOS/EOS,*,*,*,*,*,BOS/EOS'
      features.from_id(1).text.should == 'その他,間投,*,*,*,*,*'
    end
  end
  describe Okura::Serializer::CharTypes::Marshal do
    it 'コンパイルして復元できる' do
      serializer=Okura::Serializer::CharTypes::Marshal.new
      out=StringIO.new
      serializer.compile(as_io(<<-EOS),out)
DEFAULT 0 1 0  # DEFAULT is a mandatory category!
TYPE1   1 0 0
TYPE2   0 1 0
TYPE3   0 1 3

# comment

0x0021 TYPE1
0x0022 TYPE2 # comment
0x0023..0x0040 TYPE3
0x0099 TYPE1 TYPE2 # 互換カテゴリ
0xABCd TYPE1 DEFAULT
      EOS
      out.rewind

      cts=serializer.load(out)

	  cts.type_for(0x21).name.should == 'TYPE1'
	  cts.type_for(0x22).name.should == 'TYPE2'
	  cts.type_for(0x23).name.should == 'TYPE3'
	  cts.type_for(0x40).name.should == 'TYPE3'
	  cts.type_for(0x41).name.should == 'DEFAULT'
	  cts.type_for(0x99).name.should == 'TYPE1'

	  t1,t2,t3=cts.named('TYPE1'), cts.named('TYPE2'), cts.named('TYPE3')

	  t1.name.should == 'TYPE1'

	  t1.invoke?.should be_true
	  t2.invoke?.should be_false

	  t1.group?.should be_false
	  t2.group?.should be_true

	  t2.length.should == 0
	  t3.length.should == 3

	  t1.should be_accept(0x21)
	  t1.should_not be_accept(0x22)
	  t2.should be_accept(0x22)

	  t1.should be_accept(0x99)
    end
  end
  shared_examples_for 'WordDic serializer' do
    # subject : Serializer class
    it 'コンパイルして復元できる' do
      serializer=subject.new
      features_l=Okura::Features.new
      features_l.add 854,f(854)
      features_l.add 645,f(645)
      features_r=Okura::Features.new
      features_r.add 458,f(458)
      features_r.add 546,f(546)
      out=StringIO.new
      src=<<-EOS
あがなう,854,458,6636,動詞,自立,*,*,五段・ワ行促音便,基本形,あがなう,アガナウ,アガナウ,あがなう/購う/贖う,
あがめる,645,546,1234,動詞,自立,*,*,一段,基本形,あがめる,アガメル,アガメル,あがめる/崇める,
      EOS
      serializer.compile(features_l,features_r,[as_io(src)],'UTF-8',out)
      out.rewind
      wd=serializer.load(out)

      wd.possible_words('あがなう',0).should == [w('あがなう',f(854),f(458),6636)]
      wd.possible_words('あがめる',0).should == [w('あがめる',f(645),f(546),1234)]
      wd.possible_words('あがめる',1).should == []
    end
  end
  describe Okura::Serializer::WordDic::Naive do
    subject { Okura::Serializer::WordDic::Naive }
    it_should_behave_like 'WordDic serializer'
  end
  describe Okura::Serializer::WordDic::DoubleArray do
    subject { Okura::Serializer::WordDic::DoubleArray }
    it_should_behave_like 'WordDic serializer'
  end
  describe Okura::Serializer::UnkDic::Marshal do
    it 'コンパイルして復元できる' do
      serializer=Okura::Serializer::UnkDic::Marshal.new
      cts=Okura::CharTypes.new
      cts.define_type 'A',true,false,10
      cts.define_type 'Z',false,true,0
      cts.define_map 0x0001,cts.named('A'),[]
      cts.define_map 0x0002,cts.named('Z'),[]
      features_l=Okura::Features.new
      features_l.add 5,'F5'
      features_l.add 9,'F9'
      features_r=Okura::Features.new
      features_r.add 6,'F6'
      features_r.add 10,'F10'
      out=StringIO.new
      serializer.compile(cts,features_l,features_r,as_io(<<-EOS),out)
A,5,6,3274,記号,一般,*,*,*,*,*
Z,9,10,5244,記号,空白,*,*,*,*,*
      EOS
      out.rewind

      unk=serializer.load(out)
      unk.word_templates_for('A').first.cost.should == 3274
      unk.word_templates_for('Z').first.cost.should == 5244
    end
  end
  describe Okura::Serializer::Matrix::Marshal do
    it 'コンパイルして復元できる' do
      serializer=Okura::Serializer::Matrix::Marshal.new
      out=StringIO.new
      serializer.compile(as_io(<<-EOS),out)
2 3
0 0 0
0 1 1
1 0 2
1 1 3
1 2 10
      EOS
      out.rewind

      mat=serializer.load(out)
      mat.cost(0,0).should == 0
      mat.cost(1,2).should == 10
    end
  end
end

describe Okura::Matrix do
  describe '#cost' do
    it '渡された二つのFeature idを元にコストを返せる' do
      m=Okura::Matrix.new 2,2
      m.set(0,0,0)
      m.set(0,1,1)
      m.set(1,0,2)
      m.set(1,1,3)

      m.cost(1,1).should == 3
    end
  end
end

shared_examples_for 'WordDic' do
  # subject = dict builder
  def w surface
    Okura::Word.new surface,f(1),f(1),1
  end

  describe '#possible_words' do
    it '登録された単語のサイズを取得できる' do
      subject.build.word_size.should == 0
      subject.define w('aaa')
      subject.define w('bbb')
      subject.build.word_size.should == 2
    end
    it '同じ表記の単語を複数登録できる' do
      w1=Okura::Word.new 'w',f(1),f(2),100
      w2=Okura::Word.new 'w',f(10),f(20),200
      subject.define w1
      subject.define w1
      subject.define w2

      wd=subject.build

      wd.possible_words('w',0).should == [w1,w1,w2]
    end
    it '文字列と位置から､辞書に登録された単語を返せる' do
      subject.define w('aaa')
      subject.define w('bbb')
      subject.define w('aa')
      subject.define w('aaaa')
      subject.define w('aaaaa')

      wd=subject.build

      wd.possible_words('bbbaaa',0).should == [w('bbb')]
      wd.possible_words('bbbaaa',1).should == []
      wd.possible_words('bbbaaa',3).should == [w('aa'),w('aaa')]
    end
    it 'マルチバイト文字にも対応している' do
      subject.define w('ニワトリ')
      wd=subject.build

      wd.possible_words('ニワトリ',0).should == [w('ニワトリ')]
      wd.possible_words('ニワトリ',1).should == []
    end
    def matches words,str,dest
      words.each{|word| subject.define w(word) }
      dic=subject.build
      dic.possible_words(str,0).should == dest.map{|d|w(d)}
    end
    it { matches %w()        , ''        , %w() }
    it { matches %w()        , 'aaa'     , %w() }
    it { matches %w(a)       , ''        , %w() }
    it { matches %w(a)       , 'a'       , %w(a) }
    it { matches %w(a)       , 'aa'      , %w(a) }
    it { matches %w(a)       , 'b'       , %w() }
    it { matches %w(aa)      , 'a'       , %w() }
    it { matches %w(aa)      , 'aa'      , %w(aa) }
    it { matches %w(aa)      , 'aaa'     , %w(aa) }
    it { matches %w(aa)      , 'ab'      , %w() }
    it { matches %w(a aa)    , 'a'       , %w(a) }
    it { matches %w(a aa)    , 'aa'      , %w(a aa) }
    it { matches %w(a aa)    , 'aaa'     , %w(a aa) }
    it { matches %w(a aa)    , 'aab'     , %w(a aa) }
    it { matches %w(a aa ab) , 'aab'     , %w(a aa) }
    it { matches %w(a aa ab) , 'ab'      , %w(a ab) }
    it { matches %w(a aa ab) , 'aa'      , %w(a aa) }
    it { matches %w(a b)     , 'ba'      , %w(b) }
    it { matches %w(アイウ)  , 'アイウ'  , %w(アイウ) }
    it { matches %w(ア アイ) , 'アイウ'  , %w(ア アイ) }
    it { matches %w(ア アイ) , 'aアイウ' , %w() }
  end
end

describe Okura::WordDic::Naive do
  class NaiveBuilder
    def initialize
      @wd=Okura::WordDic::Naive.new
    end
    def define *args
      @wd.define *args
    end
    def build
      @wd
    end
  end
  subject { NaiveBuilder.new }
  it_should_behave_like 'WordDic'
end

describe Okura::WordDic::DoubleArray do
  subject { Okura::WordDic::DoubleArray::Builder.new }
  def base(dic)
    dic.instance_eval{@base}
  end
  def check(dic)
    dic.instance_eval{@check}
  end
  def words(dic)
    dic.instance_eval{@words}
  end
  it_should_behave_like 'WordDic'
end

describe Okura::Features do
end

describe Okura::CharTypes do
  describe '#type_for' do
	describe '文字に対するCharTypeが定義されていない場合' do
	  describe '文字種DEFAULTが定義されている場合' do
		subject {
		  cts=Okura::CharTypes.new
		  cts.define_type 'DEFAULT',false,false,0
		  cts
		}
		it 'CharType#default_typeが返る' do
		  subject.type_for('a'.ord).name.should == subject.default_type.name
		end
	  end
	  describe '文字種DEFAULTが定義されてない場合' do
		subject { cts=Okura::CharTypes.new }
		it 'エラーになる' do
		  expect { subject.type_for('a'.ord) }.to raise_error
		end
	  end
	end
  end
  describe '#define_map' do
	describe '互換カテゴリが指定された場合' do
	  subject {
		cts=Okura::CharTypes.new
		cts.define_type 'A',true,true,10
		cts.define_type 'B',true,true,10
		cts.define_map 1,cts.named('A'),[cts.named('B')]
		cts
	  }
	  it '互換カテゴリが正しく認識される' do
		subject.named('A').accept?(1).should be_true
		subject.named('B').accept?(1).should be_true
	  end
	end
  end
end

describe Okura::UnkDic do
  describe '#possible_words' do
	describe '互換カテゴリ' do
	  subject {
		cts=Okura::CharTypes.new
		cts.define_type 'KATAKANA',false,true,0
		cts.define_type 'HIRAGANA',false,true,0
		cts.define_map 'ア'.ord,cts.named('KATAKANA'),[]
		cts.define_map 'ー'.ord,cts.named('HIRAGANA'),[cts.named('KATAKANA')]
		ud=Okura::UnkDic.new cts
		ud.define 'KATAKANA',f(10),f(20),1000
		ud.define 'HIRAGANA',f(1),f(2),1000
		ud
	  }
	  it '互換カテゴリを正しく解釈する' do
		subject.possible_words('アーー',0,false).should == [w('アーー',10,20,1000)]
	  end
	end
	describe '未知語定義' do
	  describe '同一文字種に複数の未知語定義があった場合' do
		subject do
		  cts=Okura::CharTypes.new
		  cts.define_type 'A',true,true,0
		  cts.define_map 'A'.ord,cts.named('A'),[]
		  ud=Okura::UnkDic.new cts
		  ud.define 'A',f(10),f(20),1000
		  ud.define 'A',f(11),f(21),1111
		  ud
		end
		it 'すべての定義から未知語を抽出する' do
		  subject.possible_words('A',0,false).should == [
			w('A',10,20,1000),
			w('A',11,21,1111)
		  ]
		end
	  end
	end
  end
  describe '#possible_words: 文字コードによる挙動:' do
	subject do
	  cts=Okura::CharTypes.new
	  cts.define_type 'A',true,true,0
	  cts.define_map 'あ'.ord,cts.named('A'),[]
	  ud=Okura::UnkDic.new cts
	  ud.define 'A',f(10),f(20),1000
	  ud
	end
	describe 'UTF8文字列が来たとき' do
	  it '正しく解析できる' do
		subject.possible_words('あいう'.encode('UTF-8'),0,false).map(&:surface).should == %w(あ)
	  end
	end
	describe 'UTF8じゃない文字列が来たとき' do
	  it 'エラーになる' do
		expect { subject.possible_words('あいう'.encode('SHIFT_JIS'),0,false) }.to raise_error
	  end
	end
  end
  describe '#possible_words: 先頭文字のカテゴリによる挙動:' do
	def create_chartypes typename_under_test
	  cts=Okura::CharTypes.new
	  cts.define_type 'T000',false,false,0
	  cts.define_type 'T012',false,true,2
	  cts.define_type 'T100',true,false,0
	  cts.define_type 'T102',true,false,2
	  cts.define_type 'T110',true,true,0
	  cts.define_type 'T112',true,true,2
	  cts.define_type 'ZZZZ',true,true,2

	  cts.define_map 'A'.ord,cts.named(typename_under_test),[]
	  cts.define_map 'Z'.ord,cts.named('ZZZZ'),[]

	  cts
	end
	def create_subject typename_under_test
	  udic=Okura::UnkDic.new create_chartypes(typename_under_test)
	  udic.define typename_under_test,f(10),(20),1000
	  udic
	end
	describe 'invoke=0のとき' do
	  subject { create_subject 'T012' }
	  describe '辞書に単語がある場合' do
		it '未知語を抽出しない' do
		  subject.possible_words('AAA',0,true).should be_empty
		end
	  end
	end
	describe 'invoke=1のとき' do
	  describe '辞書に単語がある場合' do
		subject { create_subject 'T102' }
		it 'も､未知語を抽出する' do
		  subject.possible_words('AAAZ',0,true).should_not be_empty
		end
	  end
	  describe '先頭文字のカテゴリに対応する未知語定義がなかった場合' do
		subject { create_subject 'T112' }
		it '未知語を抽出しない' do
		  subject.possible_words('ZZ',0,false).should be_empty
		end
	  end
	  describe '辞書に単語がない場合' do
		describe 'group=0のとき' do
		  describe 'length=0のとき' do
			subject { create_subject 'T100' }
			it '未知語を抽出しない' do
			  subject.possible_words('AAAZ',0,false).should be_empty
			end
		  end
		  describe 'length=2のとき' do
			subject { create_subject 'T102' }
			it '2文字までの同種文字列を未知語とする' do
			  subject.possible_words('AAAZ',0,false).map(&:surface).should == %w(A AA)
			end
		  end
		end
		describe 'group=1のとき' do
		  describe 'length=0のとき' do
			subject { create_subject 'T110' }
			it '同種の文字列を長さ制限なしでまとめて未知語とする' do
			  subject.possible_words('AAAAAZ',0,false).map(&:surface).should == %w(AAAAA)
			end
			it '連続が一文字の場合も未知語として取れる' do
			  subject.possible_words('AZZZ',0,false).map(&:surface).should == %w(A)
			end
			it '1文字しかなくても正しく扱える' do
			  subject.possible_words('A',0,false).map(&:surface).should == %w(A)
			end
		  end
		  describe 'length=2のとき' do
			subject { create_subject 'T112' }
			it 'length=0の結果に加え､2文字までの同種文字列を未知語とする' do
			  subject.possible_words('AAAAAZ',0,false).map(&:surface).should == %w(A AA AAAAA)
			end
			it '1文字しかなくても正しく扱える' do
			  subject.possible_words('A',0,false).map(&:surface).should == %w(A)
			end
			it '2文字しかなくても正しく扱える' do
			  subject.possible_words('AA',0,false).map(&:surface).should == %w(A AA)
			end
			it '3文字しかなくても正しく扱える' do
			  subject.possible_words('AAA',0,false).map(&:surface).should == %w(A AA AAA)
			end
		  end
		end
	  end
	end
  end
end

describe Okura::Tagger do
  describe '#parse' do
    it '文字列を解析してNodesを返せる' do
      dic=Okura::WordDic::Naive.new
      dic.define w('a',1,1,0)
      dic.define w('aa',1,1,10)
      dic.define w('b',2,2,3)
      tagger=Okura::Tagger.new dic,nil

      nodes=tagger.parse('aab')

      nodes[0][0].word.should == w('BOS/EOS',0,0,0)
      nodes[4][0].word.should == w('BOS/EOS',0,0,0)
      nodes[1].size.should == 2
      nodes[3][0].word.should == w('b',2,2,3)
    end
  end
end

describe Okura::Node do
  describe '#make_bos_eos' do
    describe '#length' do
      it 'returns 1' do
        Okura::Node.mk_bos_eos.length.should == 1
      end
    end
  end
end

describe Okura::Nodes do
  describe '#mincost_path' do
    it '最小コストのパスを返せる' do
      mat=Okura::Matrix.new 2,2
      mat.set(0,1,10)
      mat.set(1,0,10)
      nodes=Okura::Nodes.new 3,mat
      nodes.add(0,Okura::Node.mk_bos_eos)
      nodes.add(1,n(w('a',1,1,10)))
      nodes.add(1,n(w('b',1,1,0)))
      nodes.add(2,Okura::Node.mk_bos_eos)

      mcp=nodes.mincost_path
      mcp.length.should == 3
      mcp[0].word.surface.should == 'BOS/EOS'
      mcp[1].word.surface.should == 'b'
      mcp[2].word.surface.should == 'BOS/EOS'
    end
    it '単語長が1を超えても動く' do
      mat=Okura::Matrix.new 2,2
      mat.set(0,1,10)
      mat.set(1,0,10)
      mat.set(1,1,10)
      nodes=Okura::Nodes.new 4,mat
      nodes.add(0,Okura::Node.mk_bos_eos)
      nodes.add(1,n(w('a',1,1,10)))
      nodes.add(1,n(w('bb',1,1,0)))
      nodes.add(2,n(w('a',1,1,10)))
      nodes.add(3,Okura::Node.mk_bos_eos)

      mcp=nodes.mincost_path
      mcp.length.should == 3
      mcp[0].word.surface.should == 'BOS/EOS'
      mcp[1].word.surface.should == 'bb'
      mcp[2].word.surface.should == 'BOS/EOS'
    end
  end
end
