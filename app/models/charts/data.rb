################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class Data

    def initialize
      @is_sorted = true
    end

    def add(label, value)
      datastore << Datum.new(label, value)
      needs_sort!
    end

    def labels
      sort!
      datastore.map { |d| d.label }.reverse
    end

    def max_value
      sort!
      datastore.first.value
    end

    def empty?
      datastore.empty?
    end

    def each
      sort!
      datastore.each do |datum|
        yield datum
      end
    end

    def each_value
      sort!
      datastore.each do |datum|
        yield datum.value
      end
    end

  private

    class Datum
      attr_reader :label, :value

      def initialize(label, value)
        @label = label.to_s
        @value = value
      end
    end

    def datastore
      @datastore ||= []
    end

    def sorted?
      @is_sorted
    end

    def finished_sort!
      @is_sorted = true
    end

    def needs_sort!
      @is_sorted = false
    end

    def sort!
      unless sorted?
        @datastore = @datastore.sort_by { |d| d.value }.reverse
        finished_sort!
      end
    end

  end
end
