class RenameStepIdToObjectIdInNotes < ActiveRecord::Migration
  def self.up
  	rename_column :notes, :step_id, :object_id
  	dateString = OracleAdapter ? "SYSDATE" : MsSQLAdapter ? "{ fn NOW() }" : "now()"
    ActiveRecord::Base.connection.execute("insert into notes ( #{OracleAdapter ? 'id,' : ''} user_id,object_id,content,object_type,created_at,updated_at)  select #{OracleAdapter ? 'notes_seq.nextval,' : ''}req.owner_id,req.id,req.notes,'Request', #{dateString} , #{dateString} from requests req where req.notes is not null")
  end

  def self.down
  	rename_column :notes, :object_id, :step_id
  	ActiveRecord::Base.connection.execute("delete from notes where notes.object_type = 'Request'")
  end

end
	