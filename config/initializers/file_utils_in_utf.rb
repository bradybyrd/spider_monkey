#encoding: utf-8
require 'fileutils'

class FileUtilsUTF
  extend FileUtils

  class << self
    def mkdir_p(list, options = {})
      fu_check_options options, OPT_TABLE['mkdir_p']
      list = fu_list(list)
      fu_output_message "mkdir -p #{options[:mode] ? ('-m %03o ' % options[:mode]) : ''}#{list.join ' '}" if options[:verbose]
      return *list if options[:noop]

      list.map {|path| path.sub(%r</\z>, '') }.each do |path|
        # optimize for the most common case
        begin
          fu_mkdir path, options[:mode]
          next
        rescue SystemCallError
          next if FileUtilsUTF.directory?(path)
        end

        stack = []
        until path == stack.last   # dirname("/")=="/", dirname("C:/")=="C:/"
          stack.push path
          path = File.dirname(path)
        end
        stack.reverse_each do |dir|
          begin
            fu_mkdir dir, options[:mode]
          rescue SystemCallError
            raise unless FileUtilsUTF.directory?(dir)
          end
        end
      end

      return *list
    end

    # deleting objects with unicode chars in their names
    # raises exception; dirty hack made.
    # this shouldn't be used anywhere else;
    def rm_r(*args)
      super *args
    rescue
      # happens in jruby-1.6.8 (no info about higher versions)
      # when folders contain unicode chars
      # brute method
      if args.first
        # "Could not delete folder with ruby utils (#{e.message}).\nUsing OS tools"
        # ignoring any other options
        list = fu_list(args.first)

        if Windows
          list.each { |path| `rd /s /q "#{path}"` }
        else
          list.each { |path| `rm -r #{path}` }
        end
      end
    end

    # `File.directory?` broken in jruby[1.6.8, 1.7.2]
    # in Windows for dirs with unicode chars;
    # this shouldn't be used anywhere else;
    def directory?(path)
      return File.directory? path
    rescue SystemCallError => e
      if Windows
        dir = ''
        cmd = "if exist \"#{path}/*\" echo dir"
        IO.popen(cmd) { |io| dir = io.read } # dir = "dir\n" if target is a directory

        return !dir.empty?
      else
        # JRUBY's' File.directory? has a bug for checking folders with chinese(unicode) characters.
        # Do not raise exception if 'Unknown Error (20047)'.In our case
        # this means a folder already exists (I hope).
        raise unless e.message.match(/Unknown Error \(20047\)/)
      end
    end

  end
end