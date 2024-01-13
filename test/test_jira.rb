require 'test/unit'
require 'pp'

#CONF ||= Wga.load_global_config File.expand_path "~/.config/l1.conf"
NOOP = true
FIX ||= false

require 'wga'
LOG ||= Goredar::Logger.new STDERR

class JiraTestCase < Test::Unit::TestCase
  def test_wgmnt
    mail_one = "High host ping PROBLEM"
    zabbix_triggers = Wgz::Triggers.new []
    zabbix_triggers.add_from_mail [mail_one]
    issue = Wga::Issue::Jira.new :triggers => zabbix_triggers
    wgmnt = issue.wgmnt
    assert wgmnt.has_key? "fields"
    wgmnt = wgmnt["fields"]
    assert_equal({ "key" => "WGMNT" }, wgmnt["project"])
    assert_equal({ "name" => "Incident" }, wgmnt["issuetype"])
    assert_equal([{ "name" => "Project: wot" }], wgmnt["components"])
    assert_equal mail_one, wgmnt["summary"]
  end
  def test_hdwr
    mail_one = "Warning host RAID_disk PROBLEM"
    mail_two = "Warning host RAID_disk PROBLEM"
    zabbix_triggers = Wgz::Triggers.new []
    zabbix_triggers.add_from_mail [mail_one]
    issue = Wga::Issue::Jira.new :triggers => zabbix_triggers
    hdwr = issue.hdwr
    assert hdwr.has_key? "fields"
    hdwr = hdwr["fields"]
    assert_equal({ "key" => "HDWR" }, hdwr["project"])
    assert_equal({ "name" => "Task" }, hdwr["issuetype"])
    assert_equal({ "name" => "Default" }, hdwr["security"])
    assert_equal({ "name" => "Medium" }, hdwr["priority"])
    assert_equal([{ "name" => "Hardware Issue" }], hdwr["components"])
    assert_equal mail_one, hdwr["summary"]
    # Two hosts are not allowed
    zabbix_triggers.add_from_mail [mail_two]
    issue = Wga::Issue::Jira.new :triggers => zabbix_triggers
    issue = Wga::Issue::Jira.new :triggers => zabbix_triggers
    assert_raise { issue.hdwr }
  end
  def test_description
    mail_one = "High host ping PROBLEM"
    zabbix_triggers = Wgz::Triggers.new []
    zabbix_triggers.add_from_mail [mail_one]
    issue = Wga::Issue::Jira.new :triggers => zabbix_triggers
    issue.wgmnt
    assert_equal 5, issue.description.lines.count
    issue.hdwr
    assert_equal 2, issue.description.lines.count
  end
  def test_project
    mail = "Average host Free RAM (<9%) PROBLEM"
    triggers = Wgz::Triggers.new []
    triggers.add_from_mail [mail]
    issue = Wga::Issue::Jira.new :triggers => triggers
    assert_equal "WGMNT", issue.project
    issue = Wga::Issue::Jira.new :triggers => triggers, :type => :hdwr
    assert_equal "HDWR", issue.project
    issue = Wga::Issue::Jira.new :triggers => triggers, :type => "hdwr"
    assert_equal "HDWR", issue.project
  end
end
