module ActionController #:nodoc:
  module Caching
    if defined?(ActiveRecord) and defined?(ActiveRecord::Observer)
      class Sweeper < ActiveRecord::Observer
        def controller
           Thread.current[:contr]
        end

        def controller=(c)
           Thread.current[:contr]=c
        end
      end
    end
  end
end
