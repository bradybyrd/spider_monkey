desc "Flog the living daylights out of your code"
task :flog do
  system 'flog app/**/*.rb | grep "\#" | head'
end

namespace :flog do

  desc "Flog the living daylights out of your controllers"  
  task :controllers do
    system 'flog app/controllers'
  end

  desc "Flog the living daylights out of your models"  
  task :models do
    system "flog app/models"
  end

  desc "Flog the living daylights out of your helpers"  
  task :helpers do
    system "flog app/helpers"
  end

end