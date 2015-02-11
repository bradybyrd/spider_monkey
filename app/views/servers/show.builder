xml.instruct!
@servers.each do |server|
  xml.server do
    xml.server_id server.id
    xml.name server.name
    server.environments.each do |env|
      xml.environment do
        xml.id env.id
        xml.name env.name
      end
    end
    xml.message @message
  end
end