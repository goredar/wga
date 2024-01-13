require 'net/ssh'
require 'net/scp'
require 'securerandom'
require 'wga/script_helpers'
require 'timeout'

module Wga
  class Ssher
    include Wga::ScriptHelpers

    @@sessions = {}

    INIT_COMMANDS = [
      "stty -echo",
      "export TERM=xterm",
      "export PS1=",
      "export WGA_FIX=#{FIX ? 1 : 0}",
      "echo _INIT_DONE_",
    ]
    EXIT_COMMANDS = [
      " history -c",
      " exit",
    ]
    SCP = [:upload, :download]
    PTY_OPTIONS = {
      :term        => "xterm",
      :chars_wide  => 192,
      :chars_high  => 108,
      :pixels_wide => 1280,
      :pixels_high => 800,
      :modes       => { Net::SSH::Connection::Term::ECHO => 0 }
    }

    # Timeouts
    SSH_CONNECT_TIMEOUT = 12
    WAIT_TIMEOUT = 12
    COMMAND_TIMEOUT = 96

    SUDO_PASS_PROMPT = "[sudo] password for".freeze

    def initialize(host = nil)
      @host = host
      @ssh = @@sessions[@host]
      unless @ssh
        timeout = (CONF[:wga][:ssh_connect_timeout] rescue SSH_CONNECT_TIMEOUT) || SSH_CONNECT_TIMEOUT
        @ssh = Net::SSH.start(@host, CONF[:wga][:ssh_user], :port => CONF[:wga][:ssh_port], :timeout => timeout)
        @ssh.transport.socket.sync = true
        @@sessions[@host] = @ssh
        LOG.success "[ssh] Connection successfully established to '#{@host}'."
      end
      @command_divider = SecureRandom.hex
      @output = Formatter.new
      @pipe = Queue.new
      @channel = nil
      @shell_count = 0
      new_shell_channel
    end

    def execute(*args, &block)
      @output = Formatter.new
      instance_exec(*args, &block)
      @output
    end

    def sh(command, args = {})
      if args[:sys]
        @channel.send_data " #{command}\n"
      else
        command_timeout = args[:timeout] || (CONF[:wga][:command_timeout] rescue COMMAND_TIMEOUT) || COMMAND_TIMEOUT
        LOG.info "[ssh] Starting '#{command}' on '#{@host}'."
        @channel.send_data  " #{command}; echo #{@command_divider}\n"
        sh_out = ""
        begin
          Timeout.timeout(command_timeout) do
            sh_out = wait_for_command_done.chomp
          end
        rescue Timeout::Error
          @channel.send_data "\x03"
          @channel.send_data "\x04"
          @channel.send_data " #{INIT_COMMANDS.last}\n"
          wait_for_init_done
          sh_out = "*WARNING* Command execution timeout (#{command_timeout}s)"
        end
        if block_given?
          sh_out = yield sh_out
        else
          @output.code(prompt(command) + (sh_out ? sh_out : "")) unless args[:silent]
        end
        LOG.success "[ssh] '#{command}' has finished on '#{@host}'."
        sh_out
      end
    end

    def sh!(command, args = {})
      if FIX
        sh command, args
      else
        LOG.warn { "[ssh] dangerous command '#{command}' skipped. Use --fix to override." }
        @output.code(prompt(command) + "Skipped due to runtime configuration. Use --fix to override.") unless args[:silent]
        ""
      end
    end

    def shell(command = nil)
      if command
        sh(command, sys: true)
        sh("echo", sys: true)
        wait_for_output
      end
      INIT_COMMANDS.each { |command| sh command, sys: true }
      wait_for_init_done
      @shell_count += 1
    end

    def shell!(command = nil)
      if FIX
        shell command
      else
        LOG.warn { "[sell] '#{command}' not started. Use --fix to override." }
        @shell_count
      end
    end

    def close
      @shell_count.times { EXIT_COMMANDS.each { |command| sh command, sys: true } }
      @channel.connection.process
    end


    private

    def new_shell_channel
      @ssh.open_channel do |channel, success|
        channel.request_pty PTY_OPTIONS do |ch, success|
          LOG.error "[ssh] Can not request pty on '#{@host}'" unless success
        end
        channel.send_channel_request "shell" do |ch, success|
          if success
            @channel = ch
            ch.on_data do |ch, data|
              @pipe << data if data
            end
            shell
          else
            LOG.error "[ssh] Can not open shell on '#{@host}'"
          end
          return
        end
      end
      @ssh.loop
      LOG.debug { "[ssh] Login shell on '#{@host}' has been started." }
    end

    def wait_for_output
      Timeout.timeout(WAIT_TIMEOUT) do
        while @pipe.empty? do @channel.connection.process(0.001); end
      end
    end

    def wait_for_init_done
      LOG.debug { "[ssh init] waiting for init done" }
      Timeout.timeout(WAIT_TIMEOUT) do
        loop do
          @channel.connection.process(0.001)
          shell_out = @pipe.pop if !@pipe.empty?
          LOG.debug { "[ssh init] got: #{shell_out}" } if shell_out
          if shell_out =~ /_INIT_DONE_/
            LOG.debug { "[ssh init] init done" }
            break
          end
        end
      end
    end

    def wait_for_command_done
      command_out = ""
      command_done = false
      until command_done do
        unless @pipe.empty?
          message = @pipe.pop
          message.each_line do |line|
            LOG.debug { "[command] Got line: #{line}" }
            if line.include?(SUDO_PASS_PROMPT)
              # Terminate prompt
              @channel.send_data "\x03"
              @channel.send_data "\x04"
              until @pipe.empty? do @pipe.pop; end
              # Return error message
              return "*WARNING* Command aborted: sudo password required"
            end
            line.include?(@command_divider) ? command_done = true : command_out += line
          end
        end
        @channel.connection.process(0.001)
      end
      if command_out =~ /\e\]0;(.*?)\a/
        @shell_prompt = $1
        command_out.gsub!( /\e\]0;(.*?)\a/, '')
      end
      #@shell_prompt = $1
      command_out.gsub!(/\x1b(\[|\(|\))[;?0-9]*[0-9A-Za-z]/, '')
      command_out.gsub!(/\x1b(\[|\(|\))[;?0-9]*[0-9A-Za-z]/, '')
      command_out.gsub!(/(\x03|\x1a)/, '')
      LOG.debug { "[ssh] Command output: #{command_out.chomp}" }
      command_out
    end

    def method_missing(symbol, *args, &block)
      # Redirect formatter methods
      return @output.public_send(symbol, *args, &block) if Formatter::UNITS.include? symbol
      # Redirect NET::SCP methods
      action = symbol.to_s.chomp('!')
      if SCP.include? action.to_sym
        begin
          LOG.info "[scp] [#{@host}] [#{args[0]}] #{action.capitalize}ing..."
          @ssh.scp.public_send(symbol, *args, &block)
          LOG.success "[scp] [#{@host}] [#{args[0]}] done!"
        rescue Exception => e
          LOG.error "[scp] [#{@host}] #{e.to_s}"
        ensure
          return
        end
      end
      super
    end

  end
end
