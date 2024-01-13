description "Restart failed loginapps"
pattern /BW loginapps ([a-z_]+)/

script :loginapp do |args = {}|
  shell "c_users"
  section "Loginapps status"
  status = sh("cluster-check-procs -v | grep loginapp:")
  failed = status.match(/^loginapp:[\d\s]+of[\d\s]+\(\-(\d)\)$/)
  if failed && FIX
    section "Restart loginapps"
    sh! "cluster-loginapp-restarter -e -r"
  end
end
