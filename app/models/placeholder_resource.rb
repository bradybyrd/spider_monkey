################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlaceholderResource < User

#  named_scope :managed_by, proc { |manager| 
#    if manager.admin?
#      {}
#    else
#      { :joins => ["INNER JOIN user_groups ON users.id = user_groups.user_id",
#                   "INNER JOIN group_management ON user_groups.group_id = group_management.group_id",
#                   "INNER JOIN users AS managers ON managers.id = group_management.manager_id"],
#        :conditions => { 'managers.id' => manager } }
#    end
#  }
  
  scope :managed_by, lambda { |manager|
    if manager.admin?
      {}
    else
      { :joins => "INNER JOIN user_groups
                  ON users.id = user_groups.user_id
                  INNER JOIN group_management
                  ON user_groups.group_id = group_management.group_id", 
         :conditions => ["users.id = group_management.manager_id AND users.id = ?", manager] }
    end
  }  

  def self.next_first_name
    if DbAdapter == 'mysql' # PP - Not removing any stuff written for MySQL
      connection.execute("SHOW TABLE STATUS LIKE '#{table_name}'").fetch_hash['Auto_increment'].rjust(5, '0')
    else
       (User.maximum('id') + 1).to_s.rjust(5, '0')
    end
  end

  def first_name
    new_record? ? PlaceholderResource.next_first_name : id.to_s.rjust(5, '0')
  end

  def last_name
    "Placeholder"
  end

  def password_required?
    false
  end

  def system_user?
    false
  end
end
