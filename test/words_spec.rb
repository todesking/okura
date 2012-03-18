#-*- coding:utf-8
require File.join(File.dirname(__FILE__),'..','lib','okura')

describe Okura::Words do
  def f n
    Okura::Feature.new n,"F#{n}"
  end
  W=Okura::Word
  it '単語を表記ごとに分類できる' do
    ws=Okura::Words.new
    w1=W.new('w',f(1),f(2),100)
    w2=W.new('w',f(2),f(3),200)
    w3=W.new('ww',f(1),f(1),100)
    id1=ws.add w1
    id2=ws.add w2
    id3=ws.add w3

    [id1,id2,id3].should == [0,0,1]
    ws.group(0).should == [w1,w2]
    ws.group(1).should == [w3]
  end
  it '単語数を返せる' do
    ws=Okura::Words.new
    ws.word_size.should == 0

    ws.add Okura::Word.new('w',f(1),f(2),100)
    ws.word_size.should == 1

    ws.add Okura::Word.new('w',f(1),f(2),100)
    ws.word_size.should == 2

    ws.add Okura::Word.new('w2',f(1),f(2),100)
    ws.word_size.should == 3
  end
end
