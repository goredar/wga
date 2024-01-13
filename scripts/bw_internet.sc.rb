description "BW_Internet_connection PROBLEM"
pattern /BW_Internet_connection/

script :bw_internet do |args = {}|
  shell "c_users"
  section "Sending stats"
  sh "cluster-sending-stats"
end
