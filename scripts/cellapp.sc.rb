description "Restart failed cellapps"
pattern /BW cellapps ([a-z_]+)/

script :cellapp do |args = {}|
  shell "c_users"
  section "Cellapp status"
  lacked_cellapps = sh("cluster-check-layout 2>&1 | grep cellapp | grep machine")
  if FIX
    section "Restart cellapps"
    restart_cellapp_map = {}
    lacked_cellapps.lines.each do |line|
      _, hostname, count = line.split(' ')
      restart_cellapp_map[count] ||= []
      restart_cellapp_map[count] << hostname.chomp(':')
    end
    restart_commands = ""
    restart_cellapp_map.each do |count, hosts|
      command = %Q[cluster-control startproc cellapp -n#{count} #{hosts.join(' ')}]
      sh! command, :silent => true
      restart_commands += prompt command
    end
    code restart_commands
    section "State after restart"
    sh "cluster-check-layout"
  end
end
