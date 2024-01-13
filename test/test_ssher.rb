require 'test/unit'
require File.expand_path("conf.rb", File.dirname(__FILE__))

FIX ||= false
NOOP ||=false

require 'wga'
LOG ||= Goredar::Logger.new STDERR

class WgaSsherTestCase < Test::Unit::TestCase

  def test_connect
    # Must start connection
    shell_1 = Wga::Ssher.new('localhost')
    # Must start new channel
    shell_2 = Wga::Ssher.new('localhost')
    assert_not_equal shell_1.instance_eval('@channel.object_id'), shell_2.instance_eval('@channel.object_id')
    assert_equal shell_1.instance_eval('@ssh.object_id'), shell_2.instance_eval('@ssh.object_id')
    # Exit all shells
    shell_1.close
    shell_2.close
  end

  def test_shell
    # Must start new (root) shell within existing one
    shell_1 = Wga::Ssher.new('localhost')
    assert_equal 2, shell_1.sh("who").lines.count
    shell_2 = Wga::Ssher.new('localhost')
    shell_2.shell "sudo -iu root"
    shell_1.sh 'cd ~/'
    shell_2.sh 'cd ~/'
    assert_equal "/home/#{%x(whoami).chomp}", shell_1.sh('pwd')
    assert_equal "/root", shell_2.sh('pwd')
    assert_equal 3, shell_1.sh("who").lines.count
    shell_1.close
    shell_2.close
  end

  def test_execute
    shell = Wga::Ssher.new('localhost')
    out = shell.execute do
      sh "cd #{File.dirname(__FILE__)}"
      sh "pwd"
    end.to_s.split($/)
    assert out.first.include?("cd #{File.dirname(__FILE__)}")
    assert_equal File.dirname(__FILE__), out.last
    shell.close
  end

  def test_sudo_password
    shell = Wga::Ssher.new('localhost')
    %x{ sudo useradd -M test }
    assert_equal "*WARNING* Command aborted: sudo password required", shell.sh("sudo -u test sudo ls")
    shell.sh("echo test_message")
    assert_equal "test_message", shell.sh("echo test_message")
    assert_equal "test_message", shell.sh("echo test_message")
    %x{ sudo userdel test }
    shell.close
  end
  def test_sh

  end

  def test_command_timeout
    shell = Wga::Ssher.new('localhost')
    assert_equal "*WARNING* Command execution timeout (0.3s)", shell.sh("sleep 10", :timeout => 0.3)
    assert_equal "test_message", shell.sh("echo test_message")
    assert_equal "*WARNING* Command execution timeout (0.3s)", shell.sh("du -sh / 2>&-", :timeout => 0.3)
    assert_equal "test_message", shell.sh("echo test_message")
    assert_equal "*WARNING* Command execution timeout (0.3s)", shell.sh("while true; do sleep 1; done", :timeout => 0.3)
    assert_equal "test_message", shell.sh("echo test_message")
    assert_equal "*WARNING* Command execution timeout (0.3s)", shell.sh("while true; do sleep 0.1; done", :timeout => 0.3)
    assert_equal "test_message", shell.sh("echo test_message")
    assert_equal "*WARNING* Command execution timeout (0.3s)", shell.sh("while true; do sleep 0.01; done", :timeout => 0.3)
    assert_equal "test_message", shell.sh("echo test_message")
    assert_equal "*WARNING* Command execution timeout (0.3s)", shell.sh("while true; do echo garbage && sleep 0.01; done", :timeout => 0.3)
    assert_equal "test_message", shell.sh("echo test_message")
    shell.close
  end
end
