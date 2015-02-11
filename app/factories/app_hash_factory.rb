class AppHashFactory

  def self.build(content, type)
    case type
      when 'json'
        AppHash::FromJson.new(content)
      when 'hash'
        AppHash::FromHash.new(content)
      else
        AppHash::FromXml.new(content)
    end
  end
end