require 'okura/loader'
module Okura
  module Compiler
    def self.compile src_dir,dest_dir
      unless File.exists? dest_dir
        Dir.mkdir dest_dir
      end

      puts 'loading dictionary...'
      tagger=Okura::Loader::MeCab.new.load src_dir

      puts 'writing...'
      open(File.join(dest_dir,'format_info'),'w'){|f|
        f.write 'marshal'
      }
      open(File.join(dest_dir,'okura.bin'),'w'){|f|
        Marshal.dump tagger,f
      }
      puts 'done'
    end
  end
end
