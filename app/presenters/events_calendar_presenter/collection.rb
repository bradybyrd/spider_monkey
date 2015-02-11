module EventsCalendarPresenter
  class Collection
    def initialize(*args)
      @collection = build_collection
    end

    def each(&block)
      @collection.each { |item| yield item }
    end
  end
end
