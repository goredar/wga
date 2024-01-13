# How to write scripts
We use simple DSL based on ruby language.
Common script structure consists of two parts: description and script itself.
Use **script** follows by it's **:name** and codeword **do** to point script start.
Close script block with **end**.
```
# Description is a human readable string
description "Simple script"
# Pattern is used to match zabbix trigger and script
pattern /simple_script/

# Start of script
script :simple do

  # Script body

# End of script
end
```

## Running commands
To run command on server just use **sh**:
```
script :simple do
  sh "date"
end
```
Output of the command will be added to common output. If you want to suppress it
add **:silent => true**, you can also assign command output to a variable in any case.
```
script :simple do
  servers_date = sh "date", :silent => true
end
```
All command are executed in the consistent login shell, so you can change working
directory or assign environment variables freely. You can also start another shell
within existing one with sudo, su, etc. using codeword **shell**.
```
script :simple do
  shell "c_users"
  # Do stuff as cluster user
end
```
You can change or examine command output by adding a block to **sh**:
```
script :simple do
  sh("ls /tmp", :silent => true) do |file_names|
    file_names.lines.each do |name|
      # process file name
    end
    "this string will be returned as command output"
  end
end
```
You can attempt to execute special commands in oder to fix problems on server.
These commands should be considered as dangerous and marked appropriately:
use *sh!* and *shell!* instead of sh and shell.
```
sh "[analyze command]"
# script processing
sh! "[fix command]"
```
It's also possible to check global constant *FIX* in script to point out code block
wich may solve the issue.
```
if FIX
  # try to resolve issue
end
```
Bash variable *WGA_FIX* is available on server.
```
sh "WGA_FIX && [fix command]"
```
You can tell wga to try to fix by adding (-f, --fix) switch to option list
```
wga --fix -i --ack
```

## Passing arguments to scripts
When you develop pattern for certain script you can use regexp captures to point
out some parameters to your script.
```
description "Show disk space utilization"
pattern /Low disk space \(<(\d+)%\) on volume (.+)/

script :low_disk do |args = {}|
  level, volume = *args[:match]
  level ||= 9
  # Process selected volume
end
```

## Running another script
You can run another script in the scope of executing one using **run** codeword
followed by script name and optionally a hostname.
```
script :simple do
  # Run on the same host
  run :free_ram
  # or on the another
  run "free_ram", :host => "ahother_host_name_or_ip_address"
end
```

## Formatting output
You can use several markers to format output of the script. They are:
- paragraph
- section
- text
- code
- bold

```
script :simple do
  section "Server status"
  sh "uptime"

  section "RAM status"
  sh "free -h"

  section "Misc"
  test "just some text"
  bold "some bold text"
  code "this will be formatted as command output"
end
```
