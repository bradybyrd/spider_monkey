namespace :perf do
  desc 'Loads CSV test fixtures from data in an existing database.  Defaults to development database.  Set RAILS_ENV to override.'
  task :load_csv, [:dump_dir] => :environment do |t, args|
    require 'csv'
    args.with_defaults(:dump_dir => 'tmp/fixtures')
    connection = ActiveRecord::Base.connection
    errors = 0
    Pathname.glob("#{Rails.root}/#{args.dump_dir}/*.csv").each do |file|
      table_name = File.basename(file, '.*')
      puts "Loading data for #{table_name}"
      connection.exec_delete("DELETE FROM #{table_name}", 'SQL', [])
      CSV.foreach(file, :headers => :first, :encoding => 'UTF-8') do |row|
        # FIXME I would like to use cached statement here, but unfortunatelly it's not so easy with JDBC Postgres Adapter
        columns_list = row.headers.map{ |x| "\"#{x}\"" }.join(', ')
        values_list = row.headers.map { |k| connection.quote(row[k]) }.join(', ')
        statement = "INSERT INTO #{table_name} (#{columns_list}) VALUES (#{values_list})"
        begin
          connection.exec_insert(statement, nil, [])
        rescue Exception => e
          puts statement.inspect
          puts e
          errors += 1
        end
      end
    end
    puts "Errors count during import is #{errors}"
  end

  def load_data

  end

  desc 'Create CSV test fixtures from data in an existing database.  Defaults to development database.  Set RAILS_ENV to override.'
  task :dump_csv, [:dump_dir] => :environment do |t, args|
    require 'csv'
    args.with_defaults(:dump_dir => 'tmp/fixtures')
    if File.exists?(args.dump_dir)
        puts "#{args.dump_dir} dir exists, clearing..."
        FileUtils.rm_f(Dir["#{args.dump_dir}/*"])
    else
        puts "#{args.dump_dir} dir doesn't exist so we're creating..."
        FileUtils.makedirs(args.dump_dir)
    end
    batch_size = 1000
    # set up the database connection
    ActiveRecord::Base.establish_connection(Rails.env)
    # get the list of tables
    all_tables = ActiveRecord::Base.connection.tables
    # reject views
    tables_to_dump = all_tables.reject { |table_name| table_name.include?("_view") }
    # remove tables to skip
    skip_tables = ["schema_migrations"]
    tables_to_dump = tables_to_dump - skip_tables

    tables_to_dump.each do |table_name|
      count = ActiveRecord::Base.connection.select("SELECT COUNT(*) AS COUNT FROM #{table_name}")[0]['count']
      next if count == 0
      CSV.open("#{Rails.root}/#{args.dump_dir}/#{table_name}.csv", 'w:UTF-8') do |csv|
        puts "Dumping #{count} records from #{table_name}"
        # Select first row only to get headers
        headers = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name} LIMIT 1")[0].keys
        csv << headers

        i = "000"
        (0..count).step(batch_size) do |current_offset|
          data = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name} ORDER BY \"#{headers.first}\" LIMIT #{batch_size} OFFSET #{current_offset}")
          data.each { |record|
            csv << record.values_at(*headers).map { |x|
                # FIXME Here we just strip out non-text data... need to think of something smarter....
                if x.kind_of? String
                  x.to_s.gsub(/[^a-z0-9\\\n\t\s'"\-:,\.]+/i, '')
                else
                  x
                end
            }
          }

          puts "Dumped #{current_offset + data.size} records"
        end
      end
    end
  end
end