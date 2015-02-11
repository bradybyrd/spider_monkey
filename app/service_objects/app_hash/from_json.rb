class AppHash::FromJson < AppHash

  private

  def create_imported_hash(json)
    JSON.parse(json)
  end

end