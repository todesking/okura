require 'okura'

module Okura
  class Console
	def load_dictionaries dict_dir
	  @word_dic=load_dict_file(dict_dir,'naist-jdic.csv'){|f|
		Okura::WordDic.load_from_io f
	  }
	  @mat=load_dict_file(dict_dir,'matrix.def'){|f|
		Okura::Matrix.load_from_io f
	  }

	  @rids=load_dict_file(dict_dir,'right-id.def'){|f|
		Okura::Features.load_from_io f
	  }

	  @char_types=load_dict_file(dict_dir,'char.def'){|f|
		Okura::CharTypes.load_from_io f
	  }

	  @unk_dic=load_dict_file(dict_dir,'unk.def'){|f|
		Okura::UnkDic.load_from_io f,@char_types
	  }

	  @dic=Okura::Dic.new(@word_dic,@unk_dic)

	  @tagger=Okura::Tagger.new @dic
	end
	private
	def load_dict_file dict_dir,name
	  puts "loading #{name}..."
	  open(File.join(dict_dir,name)){|f|
		yield f
	  }
	end
	public

	def print_usage
	  puts "USAGE: #{$0} dict_dir"
	end

	def run_console argv
	  unless argv.length==1
		print_usage
		return 1
	  end
	  load_dictionaries argv[0]
	  print 'okura> '
	  while $stdin.gets
		nodes=@tagger.parse($_.strip)
		(0...nodes.length).each{|i|
		  puts nodes[i].map{|n|"#{n.word.surface}\t#{@rids.from_id n.word.rid} #{n.word.cost}"}
		  puts
		}
		nodes.mincost_path(@mat).each{|node|
		  puts "#{node.word.surface}\t#{@rids.from_id node.word.rid}"
		}
		print 'okura> '
	  end
	  return 0
	end
  end
end
