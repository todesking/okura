#-*- coding:utf-8

require File.join(File.dirname(__FILE__),'..','lib','okura')

def as_io str
  StringIO.new str
end
def w *args
  Okura::Word.new *args
end
def f *args
  Okura::Feature.new *args
end
def n *args
  Okura::Node.new *args
end

describe Okura::Matrix do
  describe '.load_from_io' do
    describe 'left=right,マトリクスの全データがあるとき' do
      it 'インスタンスを構築できる' do
        m=Okura::Matrix.load_from_io as_io(<<-EOS)
2 2
0 0 0
0 1 1
1 0 2
1 1 3
        EOS
        m.rsize.should == 2
        m.lsize.should == 2
      end
      # TODO: エラー処理とかその他のパターン
    end
  end
  describe '#cost' do
    it '渡された二つのFeature idを元にコストを返せる' do
      m=Okura::Matrix.load_from_io as_io(<<-EOS)
2 2
0 0 0
0 1 1
1 0 2
1 1 3
      EOS
      m.cost(1,1).should == 3
    end
  end
end

describe Okura::WordDic do
  describe '.load_from_io' do
    it 'インスタンスを構築できる' do
      wd=Okura::WordDic.load_from_io(<<-EOS)
あがなう,854,854,6636,動詞,自立,*,*,五段・ワ行促音便,基本形,あがなう,アガナウ,アガナウ,あがなう/購う/贖う,
あがめる,645,645,6636,動詞,自立,*,*,一段,基本形,あがめる,アガメル,アガメル,あがめる/崇める,
      EOS
      wd.size.should == 2
    end
  end

  def w surface
    Okura::Word.new surface,1,1,1
  end

  describe '#possible_words' do
    it '文字列と位置から､辞書に登録された単語を返せる' do
      wd=Okura::WordDic.new
      wd.define w('aaa')
      wd.define w('bbb')
      wd.define w('aa')

      wd.possible_words('bbbaaa',0).should == [w('bbb')]
      wd.possible_words('bbbaaa',1).should == []
      wd.possible_words('bbbaaa',3).should == [w('aa'),w('aaa')]
    end
    it '複雑な単語にも対応している' do
      wd=Okura::WordDic.new
      wd.define w('ニワトリ')

      wd.possible_words('ニワトリ',0).should == [w('ニワトリ')]
    end
  end
  describe '#define' do
  end
end

describe Okura::Features do
  describe '.load_from_io' do
    it 'インスタンスを構築できる' do
      fs=Okura::Features.load_from_io(<<-EOS)
0 BOS/EOS,*,*,*,*,*,BOS/EOS
1 その他,間投,*,*,*,*,*
2 フィラー,*,*,*,*,*,*
3 感動詞,*,*,*,*,*,*
4 記号,アルファベット,*,*,*,*,*
      EOS
      fs.size.should == 5
      fs.from_id(0).id.should == 0
      fs.from_id(0).text.should == 'BOS/EOS,*,*,*,*,*,BOS/EOS'
    end
  end
end

describe Okura::CharTypes do
  describe '.load_from_io' do
	it 'インスタンスを構築できる' do
	  cts=Okura::CharTypes.load_from_io(<<-EOS)
DEFAULT     0 1 0
TYPE1       1 0 0
TYPE2 0 1 0
TYPE3 0 1 3

# comment

0x0021 TYPE1
0x0022 TYPE2 # comment
0x0023..0x0040 TYPE3
0x0099 TYPE1 TYPE2 # 互換カテゴリ
0xABCd TYPE1 DEFAULT
	  EOS

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
  describe '.load_from_io' do
	it 'インスタンスを構築できる' do
	  cts=Okura::CharTypes.new
	  cts.define_type 'A',true,true,10
	  cts.define_type 'Z',true,true,10
	  cts.define_map 'A'.ord, cts.named('A'), []
	  cts.define_map 'Z'.ord, cts.named('Z'), []

	  unk=Okura::UnkDic.load_from_io(<<-EOS,cts)
A,5,5,3274,記号,一般,*,*,*,*,*
Z,9,9,5244,記号,空白,*,*,*,*,*
	  EOS

	  unk.possible_words('AZ',0,false).should == [w('A',5,5,3274)]
	end
  end

  describe '#possible_words' do
	describe '互換カテゴリ' do
	  subject {
		cts=Okura::CharTypes.new
		cts.define_type 'KATAKANA',false,true,0
		cts.define_type 'HIRAGANA',false,true,0
		cts.define_map 'ア'.ord,cts.named('KATAKANA'),[]
		cts.define_map 'ー'.ord,cts.named('HIRAGANA'),[cts.named('KATAKANA')]
		ud=Okura::UnkDic.new cts
		ud.define 'KATAKANA',10,20,1000
		ud.define 'HIRAGANA',1,2,1000
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
		  ud.define 'A',10,20,1000
		  ud.define 'A',11,21,1111
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
	  ud.define 'A',10,20,1000
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
	  udic.define typename_under_test,10,20,1000
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
      dic=Okura::WordDic.new
      dic.define w('a',1,1,0)
      dic.define w('aa',1,1,10)
      dic.define w('b',2,2,3)
      tagger=Okura::Tagger.new dic

      nodes=tagger.parse('aab')

      nodes[0][0].word.should == w('BOS',0,0,0)
      nodes[4][0].word.should == w('EOS',0,0,0)
      nodes[1].size.should == 2
      nodes[3][0].word.should == w('b',2,2,3)
    end
  end
end

describe Okura::Node do
  describe '#make_eos' do
    describe '#length' do
      it 'returns 1' do
        Okura::Node.mk_eos.length.should == 1
      end
    end
  end
  describe '#make_bos' do
    describe '#length' do
      it 'returns 1' do
        Okura::Node.mk_bos.length.should == 1
      end
    end
  end
end

describe Okura::Nodes do
  describe '#mincost_path' do
    it '最小コストのパスを返せる' do
      mat=Okura::Matrix.new (0...2).map{[nil]*2}
      mat.set(0,1,10)
      mat.set(1,0,10)
      nodes=Okura::Nodes.new 3
      nodes.add(0,Okura::Node.mk_bos)
      nodes.add(1,n(w('a',1,1,10)))
      nodes.add(1,n(w('b',1,1,0)))
      nodes.add(2,Okura::Node.mk_eos)

      mcp=nodes.mincost_path mat
      mcp.length.should == 3
      mcp[0].word.surface.should == 'BOS'
      mcp[1].word.surface.should == 'b'
      mcp[2].word.surface.should == 'EOS'
    end
    it '単語長が1を超えても動く' do
      mat=Okura::Matrix.new (0...2).map{[nil]*2}
      mat.set(0,1,10)
      mat.set(1,0,10)
      mat.set(1,1,10)
      nodes=Okura::Nodes.new 4
      nodes.add(0,Okura::Node.mk_bos)
      nodes.add(1,n(w('a',1,1,10)))
      nodes.add(1,n(w('bb',1,1,0)))
      nodes.add(2,n(w('a',1,1,10)))
      nodes.add(3,Okura::Node.mk_eos)

      mcp=nodes.mincost_path mat
      mcp.length.should == 3
      mcp[0].word.surface.should == 'BOS'
      mcp[1].word.surface.should == 'bb'
      mcp[2].word.surface.should == 'EOS'
    end
  end
end
