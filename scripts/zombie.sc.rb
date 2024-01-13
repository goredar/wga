description "Get processe in Z state"
pattern /zombie/i

script :zombie do |args = {}|

  section "Processes in Z state"
  sh "ps -ejlH | grep -C 2 Z"

end
