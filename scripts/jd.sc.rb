description "XMPPCS diagnostic"
pattern /XMPPCS/

script :jd do |args = {}|

  section "XMPPCS process"
  sh "ps aux | grep beam.smp | grep -v grep"

  section "Last modification time"
  sh "ls -l /opt/jd/tmp/metrics.report"
  sh "date"

  section "updated_at field of metrics.report file"
  updated_at = sh("grep --color=never updated_at /opt/jd/tmp/metrics.report").split(' ')[2].to_i
  timestamp = sh("date '+%s'").to_i

  section "Difference"
  code "#{timestamp - updated_at} seconds"
end