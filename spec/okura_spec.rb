#-*- coding:utf-8

require File.join(File.dirname(__FILE__),'..','lib','okura')

def as_io str
  StringIO.new str
end
def feature lid,rid
  Okura::Feature.new lid,rid,''
end

describe 'helpers' do
  it { feature(0,1).right_id.should == 1 }
  it { feature(0,1).left_id.should == 0 }
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
      it '渡された二つのFeatureを元にコストを返せる' do
        m=Okura::Matrix.load_from_io as_io(<<-EOS)
2 2
0 0 0
0 1 1
1 0 2
1 1 3
        EOS
        m.cost(feature(0,1),feature(1,0)).should == 3
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
end
