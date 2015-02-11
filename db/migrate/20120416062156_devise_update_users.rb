class DeviseUpdateUsers < ActiveRecord::Migration
  def self.up
    # Database authenticatable
    change_column :users, "email", :string, :default => ""
    #change_column :users, "encrypted_password", :string, :null => false, :default => " "
    
    # Recoverable
    add_column :users, "reset_password_token", :string
    add_column :users, "reset_password_sent_at", :datetime

    # Rememberable
    # remember_created_at is already there

    # Trackable
    add_column :users, "sign_in_count", :integer, :default => 0
    add_column :users, "current_sign_in_at", :datetime
    add_column :users, "last_sign_in_at", :datetime
    add_column :users, "current_sign_in_ip", :string
    add_column :users, "last_sign_in_ip", :string

    (ActiveRecord::Base.connection.select_values ("select login from ( select count (first_name) as cnt, login from users group by login)"+  (OracleAdapter ? " ": " as dup_users " )+" where cnt > 1 ")).each do |login_name|
            i = 1
            (User.find :all, :conditions => { :login=>login_name, :system_user=>RPMTRUE  }).each do |dup_user|
                dup_user.update_attribute :login, login_name + i.to_s
                puts "User login <#{login_name}> name has been renamed to <#{login_name + i.to_s}>"
                i=i+1
            end
        end

    # Encryptable
    # password_salt is already there

    # Confirmable -> We do not want confirmable yet
    # add_column :users, "confirmation_token", :string
    # add_column :users, "confirmed_at", :datetime
    # add_column :users, "confirmation_sent_at", :datetime
    # add_column :users, "unconfirmed_email", :string #  Only if using reconfirmable
    
    ## Lockable -> We do not want lockable yet
    # add_column :users, "failed_attempts", :integer  , :default => 0 # Only if lock strategy is :failed_attempts
    # add_column :users, "unlock_token", :string    # Only if unlock strategy is :email or :both
    # add_column :users, "locked_at", :datetime

    # Token authenticatable -> We do not want token authenticatable yet
    # add_column :users, "authentication_token", :string

    ## Invitable -> We do not want invitable yet
    # add_column :users, "invitation_token", :string


    add_index :users, :login,                :unique => true
    #add_index :users, :email,                :unique => true
    # add_index :users, :confirmation_token,   :unique => true
    add_index :users, :reset_password_token, :unique => true
    # add_index :users, :unlock_token,         :unique => true
  end

  def self.down
    # remove_column :users, "confirmation_token"
    # remove_column :users, "confirmed_at"
    # remove_column :users, "confirmation_sent_at"
    remove_column :users, "reset_password_token"
    remove_column :users, "sign_in_count"
    remove_column :users, "current_sign_in_at"
    remove_column :users, "last_sign_in_at"
    remove_column :users, "current_sign_in_ip"
    remove_column :users, "last_sign_in_ip"

    remove_index :users, :login
    remove_index :users, :email
    # remove_index :users, :confirmation_token
    remove_index :users, :reset_password_token
  end
end
