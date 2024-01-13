require 'set'

module Wga
  # Load and manage scripts
  class Scripter

    @@scripts = Hash.new

    # Load scripts
    def self.load_scripts(script_dirs)
      script_dirs.each do |dir|
        Dir["#{dir}/*.sc.rb"].each { |sc| self.add_script IO.read File.expand_path sc }
      end
      LOG.debug "[app] Loaded #{@@scripts.count} scripts from #{script_dirs.count} folders."
      LOG.debug "[app] Scripts: #{@@scripts.keys.inspect}"
    end

    def self.add_script(sc)
      self.new.instance_eval sc
    end

    def self.scripts
      @@scripts
    end

    def self.match(issue)
      case issue
      when String
        return { :name => issue.to_sym } if @@scripts.has_key?(issue.to_sym)
        words = issue.split(' ')
        issue = words[2..-2].join(' ') if words.last == "PROBLEM" && words.count > 3
        @@scripts.each do |name, script|
          match = issue.match script[:pattern]
          return { :name => name, :description => issue, :match => match.captures } if match
        end
        LOG.warn "[app] Can't find script for issue: #{issue}"
        nil
      when Symbol
        if @@scripts.has_key? issue
          { :name => issue }
        else
          LOG.warn "[app] Can't find script with name '#{issue}'"
          nil
        end
      else
        LOG.warn "[app] It's not a script: #{issue.inspect}"
        nil
      end
    end

    def self.get_issues_type(scripts = [])
      scripts.reduce(Set.new) do |type, definition|
        type.add(@@scripts[definition[:name]][:issue_type] || :default)
      end
    rescue
      LOG.error "[scripter] Can't get issue type: assume default"
      Set.new([:default])
    end

    def self.run(host_name = 'localhost', scripts = [])
      return if scripts.empty?
      host_out = Formatter.new
      host = Ssher.new host_name
      scripts = [scripts] unless scripts.is_a? Array
      scripts.each do |sc|
        sc = { :name => sc } unless sc.is_a?(Hash)
        sc_name = sc[:name]
        unless @@scripts[sc_name]
          LOG.error "[script] #{sc_name} not found"
          next
        end
        if @@scripts.fetch(sc_name) && @@scripts[sc_name][:block].is_a?(Proc)
          LOG.info "[script] '#{sc_name}' has been launched on '#{host_name}'."
          script_out = host.execute(sc, &@@scripts[sc_name][:block])
          host_out.paragraph "script: #{sc_name}" if scripts.count > 1 && !script_out.empty?
          host_out += script_out
          LOG.success "[script] '#{sc_name}' has been completed successfully on '#{host_name}'."
        else
          LOG.warn "[script] '#{sc_name}' not found. Can not proceed."
        end
      end
      host.close
      host_out
    end

    # Save description while script loading
    def description(desc = "No description")
      @desc = desc
    end

    # Save pattern while script loading
    def pattern(regexp = nil)
      @regexp = regexp
    end

    # Save script block
    def script(name = nil, &block)
      unless name
        LOG.warn "[script] Script without name. Skipping."
        return false
      end
      name = name.to_sym
      if @@scripts[name]
        LOG.warn "[script] '#{name}' already exists. Skipping."
        return false
      end
      @@scripts[name] = { :description => @desc, :pattern => @regexp, :block => (block || Proc.new), :issue_type => @issue_type }
      return true
    end

    def issue(type = :default)
      @issue_type = type.to_sym
    end

  end
end
