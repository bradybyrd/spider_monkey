# Monkeypatch fix for https://github.com/rack/rack/issues/386 achieved by
# applying https://github.com/rack/rack/commit/2dfe94071497678c15cfcd8e63663d92f82958e5

# raise "remove this fix" if Gem.loaded_specs["rack"].version > Gem::Version.new("1.4.1")

module Rack
  module Utils
    if defined?(::Encoding)
      def unescape(s, encoding = Encoding::UTF_8)
        begin
          URI.decode_www_form_component(s, encoding)
        rescue
          Rails.logger.warn "DECODING on #{s.inspect} with #{encoding.inspect} FAILING."
        end
      end
    else
      def unescape(s, encoding = nil)
        URI.decode_www_form_component(s, encoding)
      end
    end
    module_function :unescape

    def parse_query(qs, d = nil)
      params = KeySpaceConstrainedParams.new

      (qs || '').split(d ? /[#{d}] */n : DEFAULT_SEP).each do |p|
        k, v = p.split('=', 2).map { |x| unescape(x) }
        next unless k || v

        if cur = params[k]
          if cur.class == Array
            params[k] << v
          else
            params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      end

      return params.to_params_hash
    end

    class KeySpaceConstrainedParams
      def []=(key, value)
        @size += key.size if key && key.respond_to?(:size) && !@params.key?(key)
        raise RangeError, 'exceeded available parameter key space' if @size > @limit
        @params[key] = value
      end
    end
  end
end
