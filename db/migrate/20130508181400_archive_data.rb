class ArchiveData < ActiveRecord::Migration
  def self.up
    objects = %w(request_template)
    objects.each {|name|
      load "#{name}.rb"
      success_flag = true
      name.classify.constantize.all.each{|instance|
        unless instance.try(:archived_at).nil?
          success_flag &= (success = instance.archive)
          say success ? "instance: #{instance.inspect} archived successfully!" : "Error while archive #{instance.inspect}. Error: #{instance.errors.inspect}"
        end
      }
      raise "Couldn't archive some items." unless success_flag
    }
  end

  def self.down
    objects = %w(request_template)
    objects.each {|name|
      load "#{name}.rb"
      success_flag = true
      name.classify.constantize.all.each{|instance|
        unless instance.try(:archive_number).nil?
          instance.archive_number = nil
          success_flag &= (success = instance.save!)
          say success ? "instance: #{instance.inspect} unarchived successfully!" : "Error while unarchived #{instance.inspect}. Error: #{instance.errors.inspect}"
        end
      }
      raise "Couldn't unarchive some items." unless success_flag
    }
  end
end
