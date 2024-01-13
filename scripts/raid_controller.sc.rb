require 'date'

description "Collect info about RAID Controller"
pattern /RAID_controller/
issue :hdwr

script :raid_controller do |args = {}|

  # Find hptool
  hptool = sh(%q[for filename in $(sudo -l | grep -E 'hpacucli|hpssacli' | awk '{print $3}'); do if [ -e "$filename" ]; then echo "$filename"; break; fi; done], :silent => true).chomp

  section "Controller Status"
  sh "sudo #{hptool} ctrl all show status"

  section "Disks Overview"
  sh "sudo #{hptool} ctrl all show config"

  # Get server's serial number
  serial = sh("sudo dmidecode -t system | grep 'Serial Number:' | head -1 | cut -d ' ' -f 3", :silent => true).chomp

  # Get hpacucli report
  hpacucli_report = "/tmp/hpacucli.report.#{serial}.zip"
  sh "sudo #{hptool} ctrl all diag file='#{hpacucli_report}'", :silent => true
  download! hpacucli_report, hpacucli_report

  # Get AHS Report
  unless sh("sudo dmidecode | grep Gen8", :silent => true).empty?
    days_before = 5

    server_date = sh("date") { |output| DateTime.parse output }
    ahs_report_zip = nil

    loop do
      # Generate log
      ahs_report = sh("sudo /usr/sbin/ahs -d /tmp -s #{(server_date - days_before).strftime "%m_%d_%Y"} 2>&- | " +
        "grep 'Successfully created' | cut -d' ' -f 8", :silent => true).chomp
      # Return if no successful
      break if ahs_report.empty?
      # Zip it
      ahs_report_zip = ahs_report + '.zip'
      sh "zip -9 #{ahs_report_zip} #{ahs_report}", :silent => true
      # Get it's size
      ahs_report_size = sh("stat -c '%s' #{ahs_report_zip}") { |out| out.chomp.to_i }
      break if ahs_report_size <= 5242880 || days_before <= 3
      # Try again
      days_before -= 1
    end
    download! ahs_report_zip, ahs_report_zip if ahs_report_zip
  end

end
