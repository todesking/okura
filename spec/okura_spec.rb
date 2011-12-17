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
      mcp[1].word.surface.should == 'a'
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
