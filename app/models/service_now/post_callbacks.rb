require 'nokogiri'

module ServiceNow
  class PostCallbacks < Nokogiri::XML::SAX::Document
    def initialize(seed_hash)
      @cnt = 0
      @line_sep = "#------------------------------------------#\n"
      @watch = seed_hash["name_fields"]
      @seed = seed_hash
    end
  
    def start_element(element, attributes)
      if element == @seed["tag_name"]
        #puts "#{@line_sep}Creating User - #{(@cnt += 1).to_s}"
        @new_user = @seed
      end
    end
  
    def end_element(element)
      return if @new_user.nil?
      if element == @seed["tag_name"]
        #puts "Final User: #{@new_user.nil? ? "" : @new_user.inspect}\n#{@line_sep}"
        ProjectServer.save_snow_data_record(@new_user)
      else
        if @watch.keys.include?(element)
          @new_user[@watch[element]] = @current
        end
      end
    end
  
    def characters(c)
      @current = c
    end
  end
end