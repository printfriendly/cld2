dir  = File.expand_path(File.dirname(__FILE__))
makefile = File.join(dir, 'Makefile')
system "ruby #{File.join(dir, "generate_makefile.rb")} --prefix=#{dir}" unless File.exists?(makefile)
