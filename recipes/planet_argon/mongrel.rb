require 'mongrel_cluster/recipes'

namespace :pa do
  namespace :mongrel do
    namespace :cluster do

    desc <<EOS
[internal] Digests mongel specific pa_* settings.  It is called by pa:digest which is called on the capistrano load event-- just after the recipes are all loaded.
EOS
    task :digest do

    # set default values for pa_port_offset and pa_mongrel_count
    # up to user to choose offset and server count that does not conflict with other apps
    # all apps together can take max 10 ports, so valid offsets are only 0-9
      set :pa_port_offset, 0 if !exists?(:pa_port_offset)
      set :pa_mongrel_count, 1 if !exists?(:pa_mongrel_count)
      if pa_port_offset + pa_mongrel_count > 10
        raise ":pa_port_offset + :pa_mongrel_count > 10!  pa only gives you 10 ports to work with"
      end

      set :mongrel_conf, "#{shared_path}/config/mongrel_cluster.yml" # seems reasonable?
      set :mongrel_servers, pa_mongrel_count  # don't set directly so can require mongrel_culster recipes first

      # CANNOT SPECIFY FULL PATH FOR NEXT 2 or u will suffer from mongrel_rails bug
      set :mongrel_pid_file, 'log/mongrel.pid' # seems reasonable?
      set :mongrel_log_file, 'log/mongrel.log' # seems reasonable?

      # per Planet Argon: ports allowed are 1xxx0-1xxx9 where xxx are last 3 digits of username
      set :mongrel_port, 10000 + user[-3,3].to_i*10 + pa_port_offset
    end


    desc <<EOS
[internal] Sets up the mongrel cluster configuration yml file.  This is triggered just after the deploy:setup task.
EOS
    task :setup_config do
      return if !exists?(:pa_account_domain)
      run "mkdir -p #{shared_path}/config"
      top.mongrel.cluster.configure
      #TODO: get rid of aliased method and do something more like that below:
      ##find_and_execute_task("mongrel:cluster:configure") 
      #needed to be explicit to avoid namespace class with pa:mongrel
      #but still not perfect solution since it requires passing in hooks manually
      #something i have no clue about since this is 3rd party
      #so still better solution lurking out there somehwere
      #gotta check with jamis
      #needs to be a funciton that does find_task as well as invoke_task_directly_with_callbacks
    end
    end
  end
end



