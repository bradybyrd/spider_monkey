xml.instruct! :xml, :version=>"1.0"
  xml.rss(:version=>"2.0"){
    xml.channel{
      xml.title("Completed Requests")
      xml.link(root_url)
      xml.description("")
      xml.language('en-us')
      for request in @requests
        xml.item do
          xml.title(request.name.nil_or_empty? ? request.number : request.name)
          xml.description(request_info_for_rss(request))
          xml.link(request_url(request))
        end
      end
    }
}