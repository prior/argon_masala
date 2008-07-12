namespace :pa do

  task :initial_digest do

    # don't do anything unless user has at least set pa_account_domain
    return if !exists?(:pa_account_domain)
    
    # clean up pa_account_domain in case user put www subdomain in front
    set :pa_account_domain, pa_account_domain.split('.')[-2,2].join('.')
      
    # if pa_target_domain unset, then assume we are targeting the account domain
    set :pa_target_domain, "www.#{pa_account_domain}" if !exists?(:pa_target_domain)

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
          set :pa_mount_point, pa_subdomain
        end
      else
        if pa_subdomain == 'www'
          set :pa_mount_point, pa_domain.gsub('.','_')
        else
          raise "not sure what to do with a secondary domain (#{pa_domain}} with an alternate subdomain (#{pa_subdomain})"
        end
      end
    end
    set :deploy_to, pa_home + '/' + pa_mount_point + '/' + application


    # setup roles on same domain (can't imagine you'll be splitting things up if you're on pa's shared server)
    server pa_target_domain, :app, :web
    role :db, pa_target_domain, :primary=>true
  end

end

#on :load, 'planet_argon:digest'
#
#
#
#require 'mongrel_cluster/recipes'
#namespace :pa do
#  namespace :mongrel do
#    task :load_setup do
#
#    # set default values for pa_port_offset and pa_mongrel_count
#    # up to user to choose offset and server count that does not conflict with other apps
#    # all apps together can take max 10 ports, so valid offsets are only 0-9
#    set :pa_port_offset, 0 if !exists?(:pa_port_offset)
#    set :pa_mongrel_count, 1 if !exists?(:pa_mongrel_count)
#    if pa_port_offset + pa_mongrel_count > 10
#    raise ":pa_port_offset + :pa_mongrel_count > 10!  pa only gives you 10 ports to work with"
#
#      set :mongrel_conf, "#{shared_path}/config/mongrel_cluster.yml" # seems reasonable?
#      set :mongrel_servers, pa_mongrel_count  # don't set directly so can require mongrel_culster recipes first
#
#      # CANNOT SPECIFY FULL PATH FOR NEXT 2 or u will suffer from mongrel_rails bug
#      set :mongrel_pid_file, 'log/mongrel.pid' # seems reasonable?
#      set :mongrel_log_file, 'log/mongrel.log' # seems reasonable?
#
#      # per Planet Argon: ports allowed are 1xxx0-1xxx9 where xxx are last 3 digits of username
#      set :mongrel_port, 10000 + user[-3,3].to_i*10 + pa_port_offset
#    end
#
#    task :setup_cluster_config do
#      run "mkdir -p #{shared_path}/config"
#      configure_mongrel_cluster
#    end
#  end
#end
#
#
#
#
#namespace :pa do
#  namespace :nginx do
#
#desc "start nginx"
#task :start do
#  # should ensure nginx is findable per http://docs.planetargon.com/Running_and_Stopping_Nginx
##  run "which nginx || which /usr/local/nginx/sbin/nginx && PATH=$PATH:/usr/local/nginx/sbin"
#
#  run 'nginx -c ~/etc/nginx/nginx.conf || /usr/local/nginx/sbin/nginx -c ~/etc/nginx/nginx.conf'
#end
#
#desc "kill nginx"
#task :stop do
#  run 'ps x | awk \'/[^\]]nginx: m/ {print $1}\' | xargs kill'
#end
#
#desc "restart nginx"
#task :restart do
#  stop_nginx
#  start_nginx
#end
#
#desc "setup nginx"
#task :setup do
#  run "mkdir -p #{pa_home}/nginx/logs"
#  run "mkdir -p #{pa_home}/nginx/tmp"
#  run "mkdir -p #{pa_home}/etc/nginx/"
#  generate_nginx_conf_header
#  generate_nginx_conf_footer
#  generate_nginx_conf_body
#  build_nginx_conf
#end
#
#desc "create nginx config file header part" 
#task :generate_nginx_conf_header do
#  nginx_conf_header = render :template => <<EOF
#worker_processes  1;
#
#pid <%=pa_home%>/nginx/tmp/nginx.pid;
#
## Valid error reporting levels are debug, notice and info
#error_log  <%=pa_home%>/nginx/logs/error.log debug; 
#
#events {
#    worker_connections  1024;
#}
#
#http {
#  access_log <%=pa_home%>/nginx/logs/access.log;
#
#  fastcgi_temp_path <%=pa_home%>/nginx/tmp/fcgi_temp;
#  client_body_temp_path  <%=pa_home%>/nginx/tmp/client_body 1 2;
#  proxy_temp_path <%=pa_home%>/nginx/tmp/proxy_temp;
#
#  include       conf/mime.types;
#  default_type  application/octet-stream;
#
#  sendfile        on;
#
#  tcp_nopush     on;
#  keepalive_timeout  65;
#  tcp_nodelay        on;
#
#  gzip  on;
#  gzip_min_length  1100;
#  gzip_buffers     4 8k;
#  gzip_types       text/plain text/html text/xhtml text/css text/js;
#
#EOF
#  pending_header_filename = "#{pa_home}/etc/nginx/nginx.conf.header.pending"
#  header_filename = "#{pa_home}/etc/nginx/nginx.conf.header"
#  put nginx_conf_header, pending_header_filename
#  run "if [[ -a #{header_filename} ]]; then rm #{pending_header_filename}; else mv #{pending_header_filename} #{header_filename}; fi"
#end
#
#desc "create nginx config file footer part" 
#task :generate_conf_footer do
#  nginx_conf_footer = render :template => <<EOF
#}
#EOF
#  pending_footer_filename = "#{pa_home}/etc/nginx/nginx.conf.footer.pending"
#  footer_filename = "#{pa_home}/etc/nginx/nginx.conf.footer"
#  put nginx_conf_footer, pending_footer_filename
#  run "if [[ -a #{footer_filename} ]]; then rm #{pending_footer_filename}; else mv #{pending_footer_filename} #{footer_filename}; fi"
#end
#
#desc "create nginx config file body part" 
#task :generate_nginx_conf_body do
#  nginx_conf_body = render :template => <<EOF
#  upstream mongrel_<%= application %> {
#    <% mongrel_servers.to_i.times do |port| %>server 127.0.0.1:<%= mongrel_port + port %><% end %>;
#  }
#
#  server {
#    listen       127.0.0.1:<%= 8000 + user[-3,3].to_i %>;
#    server_name  <%= full_target_domain %>;
#
#    root <%= current_path %>/public;
#    index  index.html index.htm;
#
#    location / {
#
#      proxy_set_header  X-Real-IP  $remote_addr;
#      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
#      proxy_set_header Host $http_host;
#      proxy_redirect false;
#      if (-f $request_filename/index.html) {
#        rewrite (.*) $1/index.html break;
#      }
#
#      if (-f $request_filename.html) {
#        rewrite (.*) $1.html break;
#      }
#
#      if (!-f $request_filename) {
#        proxy_pass http://mongrel_<%= application %>;
#        break;
#      }
#    }
#
#    error_page   500 502 503 504  /50x.html;
#    location = /50x.html {
#        root   html;
#    }
#  }
#EOF
#  pending_body_filename = "#{pa_home}/etc/nginx/nginx.conf.body.#{application}.pending"
#  body_filename = "#{pa_home}/etc/nginx/nginx.conf.body.#{application}"
#  put nginx_conf_body, pending_body_filename
#  run "if [[ -a #{body_filename} ]]; then rm #{pending_body_filename}; else mv #{pending_body_filename} #{body_filename}; fi"
#end
#
#desc "build complete nginx config from parts" 
#task :build_config do
#  header_filename = "#{pa_home}/etc/nginx/nginx.conf.header"
#  footer_filename = "#{pa_home}/etc/nginx/nginx.conf.footer"
#  body_filenames = "#{pa_home}/etc/nginx/nginx.conf.body.*"
#  run "cat #{header_filename} #{body_filenames} #{footer_filename} > #{pa_home}/etc/nginx/nginx.conf"
#end
#
###############################################################################
#
#
#
#
#
#
##----------------------------------------------------------------------------#
##                             RC.LOCAL DETAILS                               #
##----------------------------------------------------------------------------#
##            do not edit (unless you really know what you're doing)          #
##----------------------------------------------------------------------------#
#
#desc "setup rc.local"
#task :setup_rclocal do
#  run "mkdir -p #{pa_home}/etc/"
#  generate_rclocal_app_line
#  build_rclocal
#end
#
#desc "create relevant app line for rclocal" 
#task :generate_rclocal_app_line do
#  rclocal_line = render :template => <<EOF
#  rm #{shared_path}/log/mongrel.*.pid
#  mongrel_rails cluster::start -C #{shared_path}/config/mongrel_cluster.yml
#EOF
#  pending_filename = "#{pa_home}/etc/rc.local.#{application}.pending"
#  filename = "#{pa_home}/etc/rc.local.#{application}"
#  put rclocal_line, pending_filename
#  run "if [[ -a #{filename} ]]; then rm #{pending_filename}; else mv #{pending_filename} #{filename}; fi"
#end
#
#desc "build complete rc.local from parts" 
#task :build_rclocal do
#  rclocal_header = render :template => <<EOF
##! /bin/sh
#EOF
#  rclocal_footer = render :template => <<EOF
#nginx -c ~/etc/nginx/nginx.conf || /usr/local/nginx/sbin/nginx -c ~/etc/nginx/nginx.conf
#EOF
#  header_filename = "#{pa_home}/etc/header.rc.local"
#  footer_filename = "#{pa_home}/etc/footer.rc.local"
#  appline_filenames = "#{pa_home}/etc/rc.local.*"
#  put rclocal_header, header_filename
#  put rclocal_footer, footer_filename
#  run "cat #{header_filename} #{appline_filenames} #{footer_filename} > #{pa_home}/etc/rc.local"
#  run "chmod +x #{pa_home}/etc/rc.local"
#  run "rm #{header_filename} #{footer_filename}"
#end
###############################################################################
#
#
#
##----------------------------------------------------------------------------#
##                         SHARED DATABASE.YML SUPPORT                        #
##----------------------------------------------------------------------------#
##            do not edit (unless you really know what you're doing)          #
##----------------------------------------------------------------------------#
#task :update_database_yml_link do
#  run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
#end
#
#task :setup_database_yml do
#  run "mkdir -p #{shared_path}/config"
#  
## will actually keep around existing database.yml on subsequent "setups"
#  database_yml = render(:template => <<EOF)
#production:
#  adapter: mysql
#  database: <%= application %>_production
#  username: production_username
#  password:  production_password
#  host: localhost
#EOF
#  pending_filename = "#{shared_path}/config/database.yml.pending"
#  target_filename = "#{shared_path}/config/database.yml"
#  put database_yml, pending_filename
#  run "if [[ -a #{target_filename} ]]; then rm #{pending_filename}; else mv #{pending_filename} #{target_filename}; fi"
#  puts "\n\n!!! REMINDER !!! edit username/password in shared/config/database.yml !!!\n             (unless you've already done so)\n\n\n"
#end
###############################################################################
#
#
#
##----------------------------------------------------------------------------#
##                         FINAL CALCULATIONS                                 #
##----------------------------------------------------------------------------#
##            do not edit (unless you really know what you're doing)          #
##----------------------------------------------------------------------------#
#
#desc "link in production database credentials"
#task :after_update_code do
#  update_database_yml_link
#  cleanup
#end
#
#desc "create initial database.yml on setup"
#task :after_setup do
#  setup_database_yml
#  setup_mongrel_cluster_conf
#  setup_nginx
#  setup_rclocal
#end
#
#set :use_sudo, false
###############################################################################
#
#
#
#desc "do not try at home"
#task :revirginize do
#  run "rm -rf #{pa_home}/nginx"
#  run "rm -rf #{pa_home}/etc"
#  run "rm -rf #{deploy_to}"
#end
#
#
#
#
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
#
#
#
