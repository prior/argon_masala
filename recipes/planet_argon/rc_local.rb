namespace :pa do
  namespace :rc_local do

    desc "setup"
    task :setup do
      run "mkdir -p #{pa_home}/etc/"
      generate_app_line
      build
    end

    desc "create relevant app line for rclocal" 
    task :generate_app_line do
      rclocal_line = ERB.new(<<EOS).result binding 
rm #{shared_path}/log/mongrel.*.pid
mongrel_rails cluster::start -C #{shared_path}/config/mongrel_cluster.yml
EOS
      pending_filename = "#{pa_home}/etc/rc.local.#{application}.pending"
      filename = "#{pa_home}/etc/rc.local.#{application}"
      put rclocal_line, pending_filename
      run "if [[ -a #{filename} ]]; then rm #{pending_filename}; else mv #{pending_filename} #{filename}; fi"
    end

    desc "build complete rc.local from parts" 
    task :build do
      rclocal_header = ERB.new(<<EOS).result binding
#! /bin/sh
EOS
      rclocal_footer = ERB.new(<<EOS).result binding
nginx -c ~/etc/nginx/nginx.conf || /usr/local/nginx/sbin/nginx -c ~/etc/nginx/nginx.conf
EOS
      header_filename = "#{pa_home}/etc/header.rc.local"
      footer_filename = "#{pa_home}/etc/footer.rc.local"
      appline_filenames = "#{pa_home}/etc/rc.local.*"
      put rclocal_header, header_filename
      put rclocal_footer, footer_filename
      run "cat #{header_filename} #{appline_filenames} #{footer_filename} > #{pa_home}/etc/rc.local"
      run "chmod +x #{pa_home}/etc/rc.local"
      run "rm #{header_filename} #{footer_filename}"
    end

    desc "[internal] DO NOT TRY AT HOME!  Used to wipe everything and start fresh-- mainly used in testing these recipes"
    task :revirginize do
      run "rm -rf #{pa_home}/etc"
    end
  end
end

