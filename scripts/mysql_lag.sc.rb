description "Mysql replication and processlist status"
pattern /MYSQL_repl_lag_behind_(.*)/i

script :mysql_lag do |args = {}|
  section "Mysql replication status"
  sh %q(mysql -e 'show slave status\G')

  section "Process list"
  # TODO Filter ordinal processes, sort by executing time (imho)
  sh %q(mysql -e 'show processlist' | grep -v Sleep)
end
