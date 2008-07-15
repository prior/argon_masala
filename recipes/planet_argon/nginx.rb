namespace :pa do
  namespace :nginx do

    desc "start nginx"
    task :start do
      # should ensure nginx is findable per http://docs.planetargon.com/Running_and_Stopping_Nginx
      #  run "which nginx || which /usr/local/nginx/sbin/nginx && PATH=$PATH:/usr/local/nginx/sbin"

      run 'nginx -c ~/etc/nginx/nginx.conf || /usr/local/nginx/sbin/nginx -c ~/etc/nginx/nginx.conf'
    end

    desc "kill nginx"
    task :stop do
      run 'ps x | awk \'/[^\]]nginx: m/ {print $1}\' | xargs kill'
    end

    desc "restart nginx"
    task :restart do
      stop
      start
    end

    desc "setup nginx"
    task :setup do
      run "mkdir -p #{pa_home}/nginx/logs"
      run "mkdir -p #{pa_home}/nginx/tmp"
      run "mkdir -p #{pa_home}/etc/nginx/"
      generate_config_header
      generate_config_footer
      generate_config_body
      build_config
    end

    desc "[internal] create nginx config file header part" 
    task :generate_config_header do
      nginx_conf_header = ERB.new(<<EOS).result binding
worker_processes  1;

pid <%=pa_home%>/nginx/tmp/nginx.pid;

# Valid error reporting levels are debug, notice and info
error_log  <%=pa_home%>/nginx/logs/error.log debug; 

events {
    worker_connections  1024;
}

http {
  access_log <%=pa_home%>/nginx/logs/access.log;

  fastcgi_temp_path <%=pa_home%>/nginx/tmp/fcgi_temp;
  client_body_temp_path  <%=pa_home%>/nginx/tmp/client_body 1 2;
  proxy_temp_path <%=pa_home%>/nginx/tmp/proxy_temp;

  include       conf/mime.types;
  default_type  application/octet-stream;

  sendfile        on;

  tcp_nopush     on;
  keepalive_timeout  65;
  tcp_nodelay        on;

  gzip  on;
  gzip_min_length  1100;
  gzip_buffers     4 8k;
  gzip_types       text/plain text/html text/xhtml text/css text/js;

EOS
      pending_header_filename = "#{pa_home}/etc/nginx/nginx.conf.header.pending"
      header_filename = "#{pa_home}/etc/nginx/nginx.conf.header"
      put nginx_conf_header, pending_header_filename
      run "if [[ -a #{header_filename} ]]; then rm #{pending_header_filename}; else mv #{pending_header_filename} #{header_filename}; fi"
    end

    desc "create nginx config file footer part" 
    task :generate_config_footer do
      nginx_conf_footer = ERB.new(<<EOS).result binding
}
EOS
      pending_footer_filename = "#{pa_home}/etc/nginx/nginx.conf.footer.pending"
      footer_filename = "#{pa_home}/etc/nginx/nginx.conf.footer"
      put nginx_conf_footer, pending_footer_filename
      run "if [[ -a #{footer_filename} ]]; then rm #{pending_footer_filename}; else mv #{pending_footer_filename} #{footer_filename}; fi"
    end

    desc "create nginx config file body part" 
    task :generate_config_body do
      nginx_conf_body = ERB.new(<<EOS).result binding
  upstream mongrel_<%= application %> {
    <% mongrel_servers.to_i.times do |port| %>server 127.0.0.1:<%= mongrel_port + port %><% end %>;
  }

  server {
    listen       127.0.0.1:<%= 8000 + user[-3,3].to_i %>;
    server_name  <%= pa_target_domain %>;

    root <%= current_path %>/public;
    index  index.html index.htm;

    location / {

      proxy_set_header  X-Real-IP  $remote_addr;
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect false;
      if (-f $request_filename/index.html) {
        rewrite (.*) $1/index.html break;
      }

      if (-f $request_filename.html) {
        rewrite (.*) $1.html break;
      }

      if (!-f $request_filename) {
        proxy_pass http://mongrel_<%= application %>;
        break;
      }
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
  }
EOS
      pending_body_filename = "#{pa_home}/etc/nginx/nginx.conf.body.#{application}.pending"
      body_filename = "#{pa_home}/etc/nginx/nginx.conf.body.#{application}"
      put nginx_conf_body, pending_body_filename
      run "if [[ -a #{body_filename} ]]; then rm #{pending_body_filename}; else mv #{pending_body_filename} #{body_filename}; fi"
    end

    desc "build complete nginx config from parts" 
    task :build_config do
      header_filename = "#{pa_home}/etc/nginx/nginx.conf.header"
      footer_filename = "#{pa_home}/etc/nginx/nginx.conf.footer"
      body_filenames = "#{pa_home}/etc/nginx/nginx.conf.body.*"
      run "cat #{header_filename} #{body_filenames} #{footer_filename} > #{pa_home}/etc/nginx/nginx.conf"
    end

    desc "[internal] DO NOT TRY AT HOME!  Used to wipe everything and start fresh-- mainly used in testing these recipes"
    task :revirginize do
      run "rm -rf #{pa_home}/nginx"
      run "rm -rf #{pa_home}/etc"
    end
  end
end




##############################################################################


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
###############################################################################
#
#
#
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
