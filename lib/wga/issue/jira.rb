module Wga
  module Issue
    class Jira
      attr_reader :description, :project

      def initialize(args = {})
        LOG.debug "[jira] #{args}"
        args[:issue] ||= :new
        args[:type] ||= :default
        @project = args[:type] == :default ? "WGMNT" : args[:type].to_s.upcase
        if args[:issue] == :new && !respond_to?(args[:type])
          LOG.error "[jira] unsupported issue type"
          raise
        end
        @triggers = args[:triggers]
        conf = args[:conf] || {}
        user = conf[:user] || CONF[:user] || "user"
        pass = conf[:pass] || CONF[:pass] || "pass"
        @site = (conf[:jira] && conf[:jira][:url]) || (CONF[:jira] && CONF[:jira][:url]) || 'https://jira.example.com'
        require "jira"
        @jira = JIRA::Client.new(username: user, password: pass, site: @site, context_path: '', auth_type: :basic)
        if @triggers
          @hosts_info = Wgh::Viewer.new Wgh.find({ :selectors => { "hostname" => @triggers.hosts }})[:records]
          @description = @hosts_info.to_jira + $/ * 2 + @triggers.to_jira
        end
        begin
          @issue = case args[:issue]
          when /([A-Z]+\-\d+)\Z/
            # Existing issue
            @issue = @jira.Issue.find $1
            LOG.debug "[jira] Found issue: #{(@issue.key rescue 'undefinded')}"
            @issue
          when :new
            # New issue
            if @triggers && !@triggers.empty?
              @issue = @jira.Issue.build
              issue_fields = send args[:type]
              LOG.debug "[jira] issue fields: #{issue_fields}"
              @issue.save! issue_fields unless NOOP
              LOG.debug "[jira] Issue #{(@issue.key rescue 'undefinded')} created"
              @issue
            else
              raise "Reject to post new issue with empty title"
            end
          else
            raise "Invalid issue: #{args[:issue]}"
          end
        rescue JIRA::HTTPError => e
          LOG.error "[jira] #{e.response.body}"
          LOG.debug "[jira] #{e.backtrace.join($/)}"
          raise
        rescue Exception => e
          LOG.error "[jira] #{e.message}"
          LOG.debug "[jira] #{e.backtrace.join($/)}"
          raise
        end
        LOG.success "[jira] Issue is ready. Link: #{link}"
      end

      def comment(message)
        return unless @issue
        if message.empty?
          LOG.debug "[jira] Rejected to post empty comment to #{(@issue.key rescue 'undefinded')}"
        else
          @issue.comments.build.save! :body => message.to_jira unless NOOP
          LOG.success "[jira] Comment added to #{(@issue.key rescue 'undefinded')}"
        end
      rescue JIRA::HTTPError => e
        LOG.error "[jira] #{e.response.body}"
        LOG.debug "[jira] #{e.backtrace.join($/)}"
      rescue Exception => e
        LOG.error "[jira] #{e.message}"
        LOG.debug "[jira] #{e.backtrace.join($/)}"
      end

      def key
        @issue.key
      rescue
        'undefinded'
      end

      def link()
        return unless @issue
        @site.chomp('/') + "/browse/" + (@issue.key rescue 'undefinded')
      end

      def available_components
        @available_components ||= Hash[
          @jira.Project.find(@project).components.select do |comp|
            comp.name.match /(Component|Project|Realm):/
          end.map do |comp|
            [comp.name.split(/:\s?/).last.downcase, comp.name]
          end
        ]
      rescue Exception => e
        LOG.warn { "[jira] failed to get component list for #{@project}: #{e.message}" }
        LOG.debug { "[jira] #{e.backtrace.join($/)}" }
        {}
      end

      def wgmnt(fields = {})
        fields["project"] ||= { "key" => "WGMNT" }
        fields["issuetype"] ||= { "name" => "Incident" }
        proposals = []
        proposals << @triggers.to_a.map { |trig| trig["description"] }
        unless @hosts_info.appnodes.empty?
          proposals << @hosts_info.appnodes.map { |app| app["Game"] }
          proposals << @hosts_info.appnodes.map { |app| app["Realm"] }
          proposals << @hosts_info.appnodes.map { |app| app["Description"] }
        end
        unless @hosts_info.servers.empty?
          proposals << @hosts_info.servers.map { |serv| serv["Description"] }
          proposals << @hosts_info.servers.map { |serv| serv["Details"] }
          proposals << @hosts_info.servers.map { |serv| serv["Project"] }
          proposals << @hosts_info.servers.map { |serv| serv["Role"] }
        end
        components_list = match_component(proposals.flatten)
        components_list << { "name" => "Project: wot" } if components_list.empty?
        fields["components"] ||= components_list
        fields["description"] ||= @description
        fields["summary"] ||= @triggers.to_mail.split($/).last
        return { "fields" => fields }
      end

      def match_component(objects = [])
        objects = [objects] if objects.is_a? String
        objects = objects.values if objects.is_a? Hash
        match = []
        available_components.keys.each do |comp_name|
          objects.each do |string|
            next unless string.is_a?(String)
            next if string.empty?
            string.split(/[\s_\-\.]/).map(&:downcase).each do |word|
              match << { "name" => available_components[comp_name] } if comp_name == word
            end
          end
        end
        return match.uniq
      end

      def hdwr(fields = {})
        raise "[hdwr] Only single host allowed" if @triggers.hosts.count != 1
        @description = @hosts_info.to_jira(true)
        defaults = {
          "issuetype" => { "name"=>"Task" },
          "project" => { "key"=>"HDWR" },
          "priority" => { "name"=>"Medium"},
          "components" => [{ "name"=>"Hardware Issue" }],
          "description" => @description,
          # Server
          "customfield_12871" => @hosts_info.server_names.last,
          # Location
          "customfield_12873" => @hosts_info.locations.last,
          # Serial number
          "customfield_12872" => @hosts_info.serial_numbers.last,
          # Data Center
          "customfield_12875"=> { "value" => (@hosts_info.datacenters.last || "None") },
          # Security Level
          "security"=> { "name" => (@hosts_info.server_names.last.match(/^(wotcn|cn)\d+-/i) ? "KONG" : "Default") },
          # Title
          "summary"=> @triggers.to_mail.split($/).last,
        }
        return { "fields" => defaults }
      end
      alias default wgmnt
    end
  end
end
