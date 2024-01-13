description "Show memory usage"
pattern /Free RAM \(<(\d+)%\)/

script :free_ram do |args = {}|

  section "Free RAM left"
  sh "free -m"

  section "Process memory consumption"
  sh "(top -cbn1 -o%MEM || top -cbMmn1) | head -37"

  section "OOM Killer"
  server_date = sh("date '+%s'", silent: true).to_i
  server_uptime = sh("cat /proc/uptime | awk '{print $1}'", silent: true).chomp.to_i
  sh "dmesg | egrep -i 'killed process' | tac | head -n 10" do |line|
    code do
      prompt("dmesg | egrep -i 'killed process' | tac | head -n 10") +
      explode(line, :columns => 2) do |since_start, message|
        "[#{Time.at(server_date - server_uptime + since_start[1..-1].to_f).utc}] #{message}"
      end
    end
  end
end