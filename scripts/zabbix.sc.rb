description "Zabbix agent is unreachable"
pattern /Zabbix agent/i

script :zabbix do |args = {}|

  section "Zabbix agent process status"
  sh "ps aux | grep --color=never zabbix_agent | grep -v grep"
  section "Zabbix service status"
  sh "systemctl status zabbix-agent.service 2>&- || service zabbix-agent status"

  section "Memory usage"
  sh "free -m"

  section "Load Average"
  sh "uptime"

  # TODO No such file (centos7?), parse journalctl instead
  section "Zabbix agent log"
  sh "sudo tail -n 10 /var/log/zabbix/zabbix-agent.log"

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
