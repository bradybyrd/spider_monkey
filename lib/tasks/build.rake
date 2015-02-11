namespace :build do
  tmp_dir = 'tmp/build'
  artifacts_to_publish = "app config* data/clean_install data/permissions.yml data/csv db/migrate db/migration_handlers lib log public vendor Gemfile* Rakefile VERSION"

  task :copy_application do
    puts '*** Copy application ***'

    # ensure build dir exists
    sh "rm -rf #{tmp_dir}"
    sh "mkdir -p #{tmp_dir}"

    sh "cp -pR --parents #{artifacts_to_publish} #{tmp_dir}/"
    Dir.chdir(tmp_dir) do
      sh 'rm -rf app/assets'
      sh 'rm -rf log/*'
      sh 'mkdir tmp'
    end
    sh "chmod -R a+w #{tmp_dir}"

    Rake::Task['build:assets_precompile'].invoke
    #Rake::Task['build:assets_clean_expired'].invoke # temporary comment this line until we upgrade to sprocket 3.0
    Rake::Task['build:move_assets_to_build_dir'].invoke
  end

  #task :bundle_install do
  #  puts "*** Bundle install ***"
  #  Dir.chdir(tmp_dir) do
  #    sh "env BUNDLE_GEMFILE= RUBYOPT= bundle install --deployment --without development test"
  #  end
  #end

  task :assets_precompile do
    puts '*** Precompile assets ***'
    sh "rake assets:precompile RAILS_RELATIVE_URL_ROOT='/brpm' RAILS_ENV='production'"
  end

  task :assets_clean_expired do
    puts '*** Clean expired assets ***'
    sh 'rake assets:clean_expired'
  end

  task :move_assets_to_build_dir do
    puts '*** Moving assets to build dir ***'
    sh "rm -rf #{tmp_dir}/public/brpm/assets"
    sh "mkdir -p #{tmp_dir}/public/brpm/"
    sh "mv -f public/brpm/assets #{tmp_dir}/public/brpm/"
  end
 
  task :compile_ruby_files do
    puts '*** Compile ruby files ***'
    Dir.chdir(tmp_dir) do
      #existing_class_files = FileList["app/**/*.class", "config/**/*.class", "lib/**/*.class"]
      existing_class_files = FileList.new("app/**/*.class", "lib/**/*.class")
      .exclude("lib/script_support/**/*.class")
      sh "rm -f #{existing_class_files.join(' ')}" unless existing_class_files.empty?

      #compiled_ruby_files = FileList["app/**/*.rb", "config/**/*.rb", "lib/**/*.rb"] -
      #  %w(config/boot.rb config/environment.rb config/application.rb)
      compiled_ruby_files = FileList.new("app/**/*.rb", "lib/**/*.rb")
      .exclude("lib/script_support/**/*.rb")
      # should include gem 'jruby-jars' in Gemfile in :development group
      # default_jar_files = FileList[JRubyJars.core_jar_path, JRubyJars.stdlib_jar_path]

      #sh "java -classpath #{default_jar_files.join(':')} org.jruby.Main -S jrubyc #{compiled_ruby_files.join(' ')}"
      #sh "java -classpath org.jruby.Main -S jrubyc #{compiled_ruby_files.join(' ')}"
      sh "jrubyc #{compiled_ruby_files.join(' ')}"
      compiled_ruby_files.each do |ruby_file|
        File.open(ruby_file, "w") do |file|
          file.puts "require __FILE__.sub(/\\.rb$/, '.class')"
        end
      end
    end
  end

  task :create_archive => [:copy_application, :compile_ruby_files] do
    puts '*** Create archive ***'
    archive_name = "#{Dir.pwd}/brpm.zip"
    Dir.chdir(tmp_dir) do
      #sh "jar cf #{archive_name} .bundle Gemfile* Rakefile app config* db lib public vendor"
      sh "jar cf #{archive_name} #{artifacts_to_publish}"
    end
    puts "FINISH: #{Time.now.to_s}"
  end

end
