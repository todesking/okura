require 'okura'
require 'okura/loader'

module Okura
  class Console
	def run_console dict_dir
	  tagger=Okura::Loader::Marshal.new.load(dict_dir)
	  print 'okura> '
	  while $stdin.gets
		nodes=tagger.parse($_.strip)
		(0...nodes.length).each{|i|
		  puts nodes[i].map{|n|"#{n.word.surface}\t#{n.word.right.text} #{n.word.cost}"}
		  puts
		}
		nodes.mincost_path.each{|n|
		  puts "#{n.word.surface}\t#{n.word.right.text}"
		}
		print 'okura> '
	  end
	  return 0
	end
  end
end
