class ConvertStatesPsi < ActiveRecord::Migration
  def up


    puts 'Migrating plan stage instance state machines to new values...'

    begin

      ActiveRecord::Base.connection.execute("UPDATE plan_stage_instances SET aasm_state = 'compliant' WHERE aasm_state = 'created' OR aasm_state = 'started' OR aasm_state = 'completed'")
      print '.'
      ActiveRecord::Base.connection.execute("UPDATE plan_stage_instances SET aasm_state = 'noncompliant' WHERE aasm_state = 'blocked'")
      print '.'

    rescue => e
      puts "There was an error updating plan state instance states: #{ e.message }"
      puts e.backtrace.join("\n")
    else
      puts "\nPlan stage instance state machines update complete."
    end

  end

  def down

    # Note, this is a lossy migration since we have only two states in the new code -- marking them as created
    # will be ok because they will be evaluated and set to the correct state by the code once the system is
    # restarted

    puts 'Downgrading plan stage instance state machines to old values...'

    begin

      ActiveRecord::Base.connection.execute("UPDATE plan_stage_instances SET aasm_state = 'created' WHERE aasm_state = 'compliant'")
      print '.'
      ActiveRecord::Base.connection.execute("UPDATE plan_stage_instances SET aasm_state = 'blocked' WHERE aasm_state = 'noncompliant'")
      print '.'

    rescue => e
      puts "There was an error downgrading plan state instance states: #{ e.message }"
      puts e.backtrace.join("\n")
    else
      puts "\nPlan stage instance state machines downgrade complete."
    end


  end
end
