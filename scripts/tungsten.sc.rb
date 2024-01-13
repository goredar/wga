description "Tungsten latency"
pattern /tungsten: ([a-z0-9_]+) (state|relativeLatency|latency)/

script :tungsten do |args = {}|

  realm = args[:match].first if args[:match]

  if realm
    section "Tungsten status"
    state = sh "sudo -u hoperator /home/hoperator/app/tungsten/bin/tungsten_get_metric.sh -t #{realm} -m state"

    section "Tungsten last error"
    last_error = sh "sudo -u hoperator /home/hoperator/app/tungsten/bin/tungsten_get_metric.sh -t #{realm} -m pendingExceptionMessage"

    if FIX && (state.include?("OFFLINE") || !last_error.include?("NONE"))
      section "Restart Tungsten"
      sh! "sudo -u hoperator /home/hoperator/app/tungsten/bin/tungsten_restart.sh -t #{realm}"
    end
  end
end
