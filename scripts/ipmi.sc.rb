description "IPMI restarter"
pattern /IPMI ping/

script :ipmi do |args = {}|
  section "IPMI Status"
  sh "sudo ipmitool mc info"
  sh "sudo ipmitool lan print"
  section "IPMI Restart"
  sh! "sudo ipmitool mc reset warm"
end
