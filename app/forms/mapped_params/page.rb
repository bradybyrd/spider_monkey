module MappedParams
  module Page
    class << self
      def call(storage, params, relation)
        MappedParams::Param.(storage, params, :page)
      end
    end
  end
end