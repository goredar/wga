module Wga
  module Helpers

    def load_global_config(config = nil)
      YAML.load IO.read File.expand_path config
    rescue Exception => e
      LOG.error "[app] Error loading config file: specify it (-c) or install default (--install)"
      nil
    end

    def install_global_config(source, destination)
      if File.exist? destination
        merge_proc = proc { |k, o, n| o.is_a?(Hash) && n.is_a?(Hash) ? o.merge(n, &merge_proc) : n }
        conf = YAML.load(IO.read(source)).merge(YAML.load(IO.read(destination)), &merge_proc)
        File.open destination, "w" do |f|
          f.write YAML.dump conf
          LOG.success "[app] Default configuration's merged with #{destination}"
        end
      else
        FileUtils.cp source, destination
        LOG.success "Default config file's installed to #{destination}"
      end
    end

    def list_scripts(dirs)
      Wga::Scripter.load_scripts dirs
      list = ''
      if !Wga::Scripter.scripts.empty?
        max_name_length = Wga::Scripter.scripts.keys.max_by(&:length).length
        Wga::Scripter.scripts.each do |k, v|
          list << sprintf("%-#{max_name_length+5}s# %s #{$/}", k, v[:description])
        end
      else
        LOG.warn "[app] No scripts loaded"
      end
      list
    end

    def install_scripts(dir)
      %x(mkdir -p #{dir})
      if %x(cd #{dir}; git rev-parse --git-dir 2>&-).empty?
        p "git clone #{CONF[:wga][:script_url]} #{dir}"
        %x(git -c http.sslVerify=false clone #{CONF[:wga][:script_url]} #{dir})
        if $?.exitstatus == 0
          LOG.success "[app] Scripts have been installed into #{dir}"
        else
          LOG.error "[app] Can't install scripts into #{dir}"
        end
      else
        LOG.error "[app] Can't install scripts: already a git repo"
      end
    end

    def update_scripts(dirs)
      dirs.each do |dir|
        if File.directory?(dir) && !%x(cd #{dir}; git rev-parse --git-dir 2>&-).empty?
          %x(cd #{dir}; git -c http.sslVerify=false pull)
          if $?.exitstatus == 0
            LOG.success "[app] Scripts have been updated in #{dir}"
          else
            LOG.error "[app] Can't update scripts in #{dir}"
          end
        end
      end
    end

    def get_short_hostname(host)
      host = host.to_s
      case host
      when /vpn\./
        host
      when /(\d{1,3}\.){3}\d{1,3}/
        host
      when /\./
        host.split('.').first
      else
        host
      end
    end
    # Old name: for backward compatibility
    alias get_host get_short_hostname
  end
end
