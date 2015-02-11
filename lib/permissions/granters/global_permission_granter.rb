class GlobalPermissionGranter < PermissionGranter
  def grant?(action, obj)
    true
  end 
end
