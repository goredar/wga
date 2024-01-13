description "Get stats of logsDB queue"
pattern /BW_logsDB_queriesQueueSize .*/i

script :logs_db do |args = {}|

  shell "c_users"

  user = sh "whoami", :silent => true

  if user.include? "wowp" or user.include? "wotb"
    section "Overall status"
    sh %q(cluster-control get baseapps dbLib/logsDB/queriesQueueSize | awk 'BEGIN {sum = 0} {sum = sum + $7} END {print "Queue size = ", sum}')

    section "Top 20 Baseapps sends more requests"
    sh "cluster-control get baseapps dbLib/logsDB/queriesQueueSize | sort -grk7 | head -n 20"
  end

  if user.include? "wot" or user.include? "wows"
    section "Overall status: foreground"
    sh %q(cluster-control get baseapps bgTaskManager/dbLib/logsDB/foreground/queueSize | awk 'BEGIN {sum = 0} {sum = sum + $7} END {print "Queue size = ", sum}')
    section "Overall status: background"
    sh %q(cluster-control get baseapps bgTaskManager/dbLib/logsDB/background/queueSize | awk 'BEGIN {sum = 0} {sum = sum + $7} END {print "Queue size = ", sum}')

    section "Top 20 Baseapps sends more requests: foreground"
    sh "cluster-control get baseapps bgTaskManager/dbLib/logsDB/foreground/queueSize | sort -grk7 | head -n 20"
    section "Top 20 Baseapps sends more requests: background"
    sh "cluster-control get baseapps bgTaskManager/dbLib/logsDB/background/queueSize | sort -grk7 | head -n 20"
  end
end