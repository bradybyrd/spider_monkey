class AppHash::FromXml < AppHash

  private

  def create_imported_hash(xml)
    Hash.from_xml(xml)
  end

end
