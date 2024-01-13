module Wga
  module ScriptHelpers

    def run(script, args = {})
      if Scripter.scripts.has_key?(script.to_sym)
        host = args[:host] || @host
        formatter Scripter.run host, { :name => script.to_sym }.merge(args)
      end
    end

    def prompt(str = nil)
      prompt_str = @shell_prompt || ("#{CONF[:wga][:ssh_user]}@#{@host} ~" rescue "unknown@unknown ~")
      "[#{prompt_str}]#{prompt_str =~ /^root@/ ? '#' : '$'} ".concat(str ? "#{str}#{$/}" : "")
    end

    def log
      LOG
    end

    def to_pretty_size(number)
      number = number.to_i
      %w(B KB MB GB TB PB EB ZB).zip(0.upto(7).map{ |n| 1024 ** n }).each do |str, int|
        return sprintf "%5s #{str}" % (number.to_f / int).round(1) if number < int * 1024
      end
      "#{(number.to_f / 1024 ** 8).round(1)} YB"
    end

    def explode(str, options = {})
      return(str) if !str || str.empty?
      if block_given?
        out = str.lines.map { |line| yield *line.chomp.split(' ', options[:columns].to_i) }.join($/)
        return out.chomp
      end
      str
    end

  end
end
