# -*- coding: utf-8 -*-
$LOAD_PATH.unshift '.'
require 'okura'

dict_dir=$*[0]

puts 'loading words'
@dic=open(File.join(dict_dir,'naist-jdic.csv')){|f|
  Okura::WordDic.load_from_io f
}
puts 'loading mat'
@mat=open(File.join(dict_dir,'matrix.def')){|f|
  Okura::Matrix.load_from_io f
}

puts 'loading features'
@rids=open(File.join(dict_dir,'right-id.def')){|f|
  Okura::Features.load_from_io f
}

@tagger=Okura::Tagger.new @dic

def run_console
  print 'okura> '
  while $stdin.gets
    nodes=@tagger.parse($_.strip)
    (0...nodes.length).each{|i|
      puts nodes[i].map{|n|"#{n.word.surface}\t#{@rids.from_id n.word.rid} #{n.word.cost}"}
      puts
    }
    nodes.mincost_path(@mat).each{|node|
      puts "#{node.word}\t#{@rids.from_id node.word.rid}"
    }
    print 'okura> '
  end
end

if __FILE__==$0
  run_console
end
