namespace :pa do

  desc <<EOS
[internal] Digests general pa_* settings.  
It is called on the capistrano load event -- 
  just after the recipes are all loaded.
EOS
  task :digest do

    # don't do anything unless user has at least set pa_account_domain
    return if !exists?(:pa_account_domain)

    set :use_sudo, false
    
    # clean up pa_account_domain in case user put www subdomain in front
    set :pa_account_domain, pa_account_domain.split('.')[-2,2].join('.')
      
    # if pa_target_domain unset, then assume we are targeting the account domain
    set :pa_target_domain, "www.#{pa_account_domain}" if !exists?(:pa_target_domain)
    set :pa_target_domain, "www.#{pa_target_domain}" if pa_target_domain.count('.')==1

    set :pa_target_hostname, pa_target_domain.split('.')[-2,2].join('.')
    set :pa_server_domain, 'www.' + pa_target_hostname

    # determine deploy_to
    # assumptions based on Planet Argon VHCS experience:
    #   1) home directory (~ or $HOME) is at /var/www/virtual/primary_domain.com
    #   2) www.primary_domain.com root is at home directory
    #   3) www.secondary_domain.com root is at ~/secondary_domain_com
    #   4) subdomain.primary_domain.com root is at ~/subdomain
    #   5) secondary domains cannot have subdomains
    #   6) rails app lies at site_root/application/[releases,shared,current]
    #
    set :pa_home, "/var/www/virtual/#{pa_account_domain}" if !exists?(:pa_home)
    # assume mounting directory is default provided by vhcs if not specified
    if !exists?(:pa_mount_point)
      pa_subdomain, pa_domain = pa_target_domain.split('.',2)
      if pa_domain == pa_account_domain
        if pa_subdomain == 'www'
          set :pa_mount_point, ""
        else
          set :pa_mount_point, '/' + pa_subdomain
        end
      else
        if pa_subdomain == 'www'
          set :pa_mount_point, '/' + pa_domain.gsub('.','_')
        else
          raise "not sure what to do with a secondary domain (#{pa_domain}} with an alternate subdomain (#{pa_subdomain})"
        end
      end
    end
    set :deploy_to, pa_home + pa_mount_point + '/' + application


    # setup roles on same domain (can't imagine you'll be splitting things up if you're on pa's shared server)
    server pa_server_domain, :app, :web
    server pa_server_domain, :db, :primary=>true
    # not allowed to define role in namespace !? above is a workaround?

    mongrel.cluster.digest
  end


  desc <<EOS
[internal] NUCLEAR! Do not use unless you know what you are doing!
This task will wipe everything on the remote machine.  At the moment 
this includes some files involved in sister apps.  This task is used
mainly just to test these recipes.
EOS
  task :revirginize do
    run "rm -rf #{deploy_to}"
    nginx.revirginize
    rc_local.revirginize
  end

  
#  namespace :applications do
#
#    desc <<EOS
#[internal] 
#EOS
#    task :add do
#
#    end
#
#    task :remove do
#    end
#
#    task :read do
#      
#    end
#
#end
end

on :load, 'pa:digest'
after "deploy:setup", "pa:mongrel:cluster:setup_config", "pa:nginx:setup", "pa:rc_local:setup"


#pull in other subrecipes
Dir[File.join(File.dirname(__FILE__),'planet_argon','*.rb')].each {|sub| load(sub)}




