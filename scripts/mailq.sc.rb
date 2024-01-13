description "mailq"
pattern /mail queue length is high/

script :mailq do |args = {}|

  section "mailq status"
  sh "mailq | tail -n 1"

  section "top 10 emails"
  sh %q(mailq | sed -r '/[A-Z0-9]+\*/,+1 d' | sed -e 's/^[ \t]*//' | sed '/^$/d' | sed -n '4~3p' | sort | uniq -c | sort -rn | head -n 10)

  section "top 10 errors"
  sh %q(mailq | sed -r '/[A-Z0-9]+\*/,+1 d' | sed -e 's/^[ \t]*//' | sed '/^$/d' | sed -n '3~3p' | sort | uniq -c | sort -rn | head -n 10)

end
