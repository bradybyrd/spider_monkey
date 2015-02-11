require 'rake'

namespace :app do
  
  task :update => [:update_code, :update_db,  :restart_services] 
  
  task :restart_services do
    puts "Restarting Web and Application Server"
    puts "=" * 80
    sh 'sudo /etc/init.d/thin restart'
    sh 'sudo /etc/init.d/nginx stop'
    sh 'sudo /etc/init.d/nginx start'
    puts "\n\n\n"
  end 

  task :update_code do
    puts "Updating codebase"
    puts "=" * 80
    system 'git checkout HEAD .'
    system 'git pull'
    puts "\n\n\n"
  end
  
  task :update_db do
    RAILS_ENV = 'production'
    puts "Updating database in environment #{RAILS_ENV}"
    puts "=" * 80
    Rake::Task['db:migrate'].invoke
    puts "\n\n\n"
  end

  task :archive => [:git_archive, :upload_tarball]

  task :git_archive do
    sh "git archive master | gzip > /tmp/latest_master.tgz"
  end

  task :upload_tarball do
    sh "scp /tmp/latest_master.tgz deploy@streamstep.edgecase.com:/home/deploy/apps/streamstep/current/app"
  end

  task :remove_archive do
    sh "rm /tmp/latest_master.tgz; touch /tmp/latest_master.tgz"
    sh "scp /tmp/latest_master.tgz deploy@streamstep.edgecase.com:/home/deploy/apps/streamstep/current/app"
  end

  namespace :archive do

    ExtraBranches = %w(novartis novartis_staging)

    ExtraBranches.each do |branch|
      task branch => ["git_archive_#{branch}", "upload_tarball_#{branch}"]

      task "git_archive_#{branch}" do
        sh "git archive #{branch} | gzip > /tmp/latest_#{branch}.tgz"
      end

      task "upload_tarball_#{branch}" do
        sh "scp /tmp/latest_#{branch}.tgz deploy@streamstep.edgecase.com:/home/deploy/apps/streamstep/current/app"
      end
    end

  end

  namespace :remove_archive do
    
    ExtraBranches.each do |branch|
      task branch do
        sh "rm /tmp/latest_#{branch}.tgz; touch /tmp/latest_#{branch}.tgz"
        sh "scp /tmp/latest_#{branch}.tgz deploy@streamstep.edgecase.com:/home/deploy/apps/streamstep/current/app"
      end
    end

  end
end

