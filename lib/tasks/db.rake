namespace :db do
  namespace :load do
    Dir[File.join(Rails.root, 'data', 'sql', '*.sql')].each do |sql|
      dump = File.basename(sql, '.sql')
      desc "Loads #{dump} into the database"
      task dump => ['db:drop', 'db:create'] do
        puts "Loading #{sql}..."
        `script/dbconsole < #{sql}`
      end
    end
  end
end
