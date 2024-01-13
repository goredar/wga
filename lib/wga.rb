require 'wga/version'
require 'wga/formatter'
require 'wga/scripter'
require 'wga/ssher'
require 'wga/helpers'
require 'wga/issue/jira'
require 'goredar/logger'
require 'wgh'
require 'wgz'
require 'yaml'
require 'fileutils'
require 'set'

module Wga
  extend Helpers

  def self.run_scripts(options)
    # Parse all script from all avaliable places
    Scripter.load_scripts options[:script_dir]

    # @script_map[#HOST] will contain array of scripts should be executed
    @script_map = {}

    # Process tirggers (find host and script corresponding to issue)
    @zbx_triggers = Wgz::Triggers.new options[:triggers_json]
    @zbx_triggers.add_from_mail options[:triggers]

    if !@zbx_triggers.empty?
      @zbx_triggers.each do |trigger|
        host = get_short_hostname trigger["host"]
        @script_map[host] ||= []
        @script_map[host].push Scripter.match trigger["description"]
      end
    end
    # Add scripts from options
    if !options[:hosts].empty? && !options[:scripts].empty?
      options[:hosts].map!{ |h| get_short_hostname h }.uniq!
      options[:scripts].uniq!
      options[:hosts].each do |host|
        @script_map[host] ||= []
        @script_map[host] += options[:scripts].map { |sc| Scripter.match sc}
      end
    end

    # Deduplicate script and remove nils (where are no corresponding script)
    @script_map.each { |host, scripts| @script_map[host] =  scripts.compact.uniq }
    @script_map = @script_map.reject { |host, scripts| scripts.empty? }

    LOG.debug "Following hosts will be processed: #{@script_map}"

    output = Formatter.new
    output_lock = Mutex.new
    threads = []
    # Execute on each host and make a single output
    LOG.info "[app] Processing hosts..."
    unless NOOP
      @script_map.each do |host, scripts|
        next if scripts.empty?
        threads << Thread.new do
          begin
            LOG.debug "[#{host}] New thread started"
            host_out = Formatter.new
            script_out = Scripter.run host, scripts
            if @script_map.count > 1 && !script_out.empty?
              host_out.paragraph "host [#{host}]" if @script_map.count > 1
            end
            host_out += script_out
            output_lock.synchronize { output += host_out }
          rescue Exception => e
            LOG.error "[#{host}] #{e}"
            LOG.debug "[#{host}] #{e.backtrace.join($/)}"
          ensure
            LOG.debug "[#{host}] Thread exited"
          end
        end
      end
    end
    # Wait for threads
    threads.each { |thread| thread.join }
    LOG.success "[app] All hosts done"

    if options[:comment]
      output.text options[:comment]
      LOG.debug "[comment] #{options[:comment]}"
    end

    # Post comment to issue (create if needed)
    if options[:issue]
      LOG.info "[app] Processing issue..."
#      if output.empty?
#        LOG.error "[jira] Reject to post issue with empty comment"
#      end
      # Get issue type
      issue_type = options[:issue_type]
      unless issue_type
        issue_type = @script_map.reduce(Set.new) do |type, host_map|
          type.merge Scripter.get_issues_type host_map[1]
        end rescue Set.new([:default])
        if issue_type.to_a.size != 1
          LOG.warn "[app] Can't determine issue type: use default"
          issue_type = :default
        else
          issue_type = issue_type.to_a.first
        end
      end
      # Get right provider
      begin
        issue_provider = Wga::Issue.const_get CONF[:wga][:issue_system].to_s.capitalize
      rescue
        LOG.error "[app] Invalid issue provider: use default"
        issue_provider = Wga::Issue::Jira
      end
      # Find or create
      issue = issue_provider.new issue: options[:issue], type: issue_type, triggers: @zbx_triggers rescue nil
      if issue
        # Comment issue
        if options[:add_info_to_comment]
          output = Formatter.new.tap{ |f| f.text issue.description } + output
        end
        issue.comment output unless output.empty?
        # Acknowledge triggers
        if options[:ack] && !NOOP
          message = options[:ack] == :issue ? issue.link : options[:ack]
          if message
            @zbx_triggers.set_acknowledge! message
            LOG.warn "[app] Following triggers have been acknowledged:"
            puts @zbx_triggers.to_table
          else
            LOG.warn "[app] Reject to acknowledge triggers: empty message"
          end
        end
      end
    # Print to console
    else
      unless output.empty?
        LOG.info "[console] Generating output..."
        LOG.debug "[console] output format: #{options[:format]}"
        output = case options[:format]
        when :jira
          output.to_jira
        else
          output.to_console
        end
        $stdout.puts output
      end
    end
  end
end
