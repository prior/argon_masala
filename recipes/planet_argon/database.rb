#TODO: make more generic for other databases as well
#      perhaps pull from something like config/database.production.yml that doesn't get checked in
#      perhaps keeping a list of apps and dirs and databases used would help

namespace :pa do
  namespace :database do
    task :setup_config do
      mysql_password = Capistrano::CLI.password_prompt("Production MySQL password: ")

      require 'yaml'
      spec = {
        "production" => {
          "adapter" => "mysql",
          "database" => exists?(:database) ? database : "#{application}_production",
          "username" => exists?(:database_user) ? database_user : user,
          "host" => "localhost",
          "password" => mysql_password } }

      run "mkdir -p #{shared_path}/config"
      put(spec.to_yaml, "#{shared_path}/config/database.yml")
    end
    after "deploy:setup", "pa:database:setup_config"

    task :linkin_config do
     run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
    end
    after "deploy:update_code", "pa:database:linkin_config"

    #TODO: needs to be reworked for generic/public consumption
    task :pull_latest_db do
      run "#{pa_site_root}/cgi-bin/mysql_backup"
      get "#{pa_site_root}/backups/latest.tar.gz", "db/latest.tar.gz"
#  system "C:\\Program Files\\7-Zip\\7z e -odb db\\latest.tar.gz"
#  system "C:\\Program Files\\7-Zip\\7z e -odb db\\latest.tar"
#  system "del db\\latest.tar*"
  system "tar -xzvf db/latest.tar.gz"
  username = "root"
  password = "."
  database = "ck_development"
  system "mysql -u#{username} -p#{password} -D#{database} < #{application}_production.sql"
  system "rm #{application}_production.sql"
#  system "mysql -u#{username} -p#{password} -D#{database} < db/#{application}_production.sql"
#  system "del db\\#{application}_production.sql"
   end
  end
end




##----------------------------------------------------------------------------#
##                         SHARED DATABASE.YML SUPPORT                        #
##----------------------------------------------------------------------------#
##            do not edit (unless you really know what you're doing)          #
##----------------------------------------------------------------------------#
#task :pull_latest_db do
#  run "#{pa_site_root}/cgi-bin/mysql_backup"
#  get "#{pa_site_root}/backups/latest.tar.gz", "db/latest.tar.gz"
##  system "C:\\Program Files\\7-Zip\\7z e -odb db\\latest.tar.gz"
##  system "C:\\Program Files\\7-Zip\\7z e -odb db\\latest.tar"
##  system "del db\\latest.tar*"
#  system "tar -xzvf db/latest.tar.gz"
#  username = "root"
#  password = "."
#  database = "ck_development"
#  system "mysql -u#{username} -p#{password} -D#{database} < #{application}_production.sql"
#  system "rm #{application}_production.sql"
##  system "mysql -u#{username} -p#{password} -D#{database} < db/#{application}_production.sql"
##  system "del db\\#{application}_production.sql"
#end
###############################################################################
