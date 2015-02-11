class FileInUTF
  class << self
    def open(*args)
      # args[0] -- filename
      # args[1] -- mode(optinal)
      # UTF-8 as default charset

      if !args[1].nil?
        mode      = args[1]
        mode      = "#{mode}:UTF-8" if mode.match(':').nil?
        args[1]   = mode
      end

      if block_given?
        filestream    = File.open(*args) {|f|
          yield f
        }
      else
        filestream    = File.open(*args)
      end

      return filestream
    end

    def new(*args)
      filestream = self.open(*args)

      return filestream
    end
  end
end