module MappedParams
  module Multiparameters
    class << self
      # Converts date params:
      #   {
      #     "start_at" => "31/08/2013",
      #     "finish_at" => "31/09/2013"
      #   }
      #   # =>
      #   {
      #     :"finish_at(1i)" => "2013",
      #     :"finish_at(2i)" => "08",
      #     :"finish_at(3i)" => "31",
      #     :"start_at(1i)" => "2013",
      #     :"start_at(2i)" => "09",
      #     :"start_at(3i)" => "31"
      #   }
      def call(params, relation)
        model_key = nil
        params.each_key {|k| model_key = k if k.match /deployment/ }

        if params.include? model_key
          [[:start_at, :start_at], [:finish_at, :finish_at]].each do |helper_param_name, param_name|
            if params[model_key].include? helper_param_name
              ordered_date_chunked(model_key, params, helper_param_name).each_with_index { |item, index|
                params[model_key][:"#{param_name}(#{index + 1}i)"] = item || ''
              } # set appropriate multiparameter attributes: "31/08/2013" => ["2013", "08", "31"] => { "deployment_window" => { "start_at(1i)" => "2013", "start_at(2i)" => "08", "start_at(3i)" => "31" } }

              params[model_key].delete helper_param_name
            end
          end
        end
        params
      end

      def ordered_date_chunked(model_key, params, param_name)
        params[model_key][param_name]
          .split(/[-\/\s]/) # convert formatted date to array: "Aug-31-2013" => ["Aug", "31", "2013"]
          .map { |date_chunk|
            Date::ABBR_MONTHNAMES.include?(date_chunk) ? '%02d' % Date::ABBR_MONTHNAMES.index(date_chunk).to_s : date_chunk
          } # convert month abbreviation to number if needed: ["Aug", "31", "2013"] => ["08", "31", "2013"]
          .values_at(*date_chunks_order)  # reorder date chunks to year-month-day: ["08", "31", "2013"] => ["2013", "08", "31"]
      end

      def date_chunks_order
        @date_chunks_order = %w( Y m b d ).reduce([]) { |memo, chunk|
          memo << date_format_chunks.index(chunk)
        }.compact # get indexes of year, month, day from date format pattern string: "mdY" => [year = 2, month = 0, day = 1]
      end

      def date_format_chunks
        @date_format_chunks = GlobalSettings[:default_date_format]
          .gsub(/[^Ymbd]/, '')  # remove all except year, month, day from date format pattern string: "%m/%d/%Y %I:%M %p" => "mdY"
          .split('').uniq # remove all repetitions: "mmddYYYY" => "mdY"
      end
    end
  end
end
