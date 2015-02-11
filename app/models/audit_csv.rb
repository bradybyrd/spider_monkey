################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AuditCSV
  def initialize collection
    @collection = collection
    @columns = []
    yield self if block_given?
    self
  end

  def add_column name, desc, default, message = nil
    @columns << Column.new(name, desc, default, message)
  end

  def to_csv
    CSV.generate do |csv|
      csv << @columns.map(&:name)
      csv << @columns.map(&:description) # two row header

      @collection.each do |obj|
        csv << @columns.map { |col| col.value_for(obj) }
      end
    end
  end

  class Column
    attr_reader :name, :description
    def initialize name, description, default_value, message
      if message.is_a?(Hash)
        @messages = message.inject(Hash.new(lambda { 'N/A' })) do |hash, (type, msg)|
          if msg.respond_to?(:call)
            hash[type] = msg
          else
            hash[type] = lambda { |obj| obj.send(msg) }
          end
          hash
        end
      elsif message.respond_to?(:call)
        @messages = Hash.new(message)
      else
        @messages = Hash.new(lambda { |obj| obj.send(message) })
      end

      @name          = name 
      @description   = description 
      @default_value = default_value 
    end

    def value_for(obj)
      using(obj) do
        value = messages[current_object.class].call(current_object)
        value.nil? ? @default_value : value
      end
    end

    def messages
      @messages
    end

    def using obj, &block
      col = dup
      col.current_object = obj
      col.instance_eval(&block)
    end

    def current_object=(obj)
      @current_object = obj
    end

    def current_object
      @current_object
    end
  end
end
