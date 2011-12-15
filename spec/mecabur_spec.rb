#-*- coding:utf-8

require File.join(File.dirname(__FILE__),'..','lib','MeCabur')

describe MeCabur::Tagger do
  it {
    dic=mock 'dic'

    tagger=MeCabur::Tagger.new dic

    result=tagger.wakati 'こんにちは'
    result.should == %w(こんにちは)
  }
end
