require 'test/unit'
require File.expand_path("conf.rb", File.dirname(__FILE__))

FIX ||= false
NOOP ||=false

require 'wga'
LOG ||= Goredar::Logger.new STDERR

class WgaScriptHelpersTestCase < Test::Unit::TestCase

  def test_to_pretty_size
    script = %q[
      script :test_pretty do
        text to_pretty_size "123"
        text to_pretty_size "1024"
        text to_pretty_size "10240"
        text to_pretty_size "259633"
        text to_pretty_size "8473362"
        text to_pretty_size "56732856"
        text to_pretty_size "385634095"
        text to_pretty_size "1073741824"
        text to_pretty_size "18253611008"
        text to_pretty_size "874635520554"
      end
    ]
    Wga::Scripter.add_script script
    pretty = ["123.0 B", "  1.0 KB", " 10.0 KB", "253.5 KB", "  8.1 MB", " 54.1 MB", "367.8 MB", "  1.0 GB", " 17.0 GB", "814.6 GB"]
    assert_equal pretty, Wga::Scripter.run('localhost', :test_pretty).to_s.split($/)
  end

  def test_prompt
    script = %Q[
      script :test_prompt do
        text prompt "whoami"
        sh "whoami"
        sh 'cd /tmp'
        sh "pwd"
      end
    ]
    Wga::Scripter.add_script script
    prompt_default = "[goredar@localhost ~]$ whoami"
    user = %x(whoami).chomp
    prompt_real = "[#{user}@#{%x(hostname).chomp}:~]$ whoami"
    prompt_real_cd = "[#{user}@#{%x(hostname).chomp}:~]$ cd /tmp"
    prompt_real_pwd = "[#{user}@#{%x(hostname).chomp}:/tmp]$ pwd"
    assert_equal [prompt_default, prompt_real, user, prompt_real_cd, prompt_real_pwd, "/tmp"], Wga::Scripter.run('localhost', :test_prompt).to_s.split($/)
  end

  def test_explode
    script = %q[
      script :test_explode do
        text explode("a b\nc d\ne f\ng h\ni j") { |letter1, letter2| "#{letter1.next} #{letter2}" }
        text explode("a b c\nd e f\ng h i", :columns => 2) { |letter1, other| "#{letter1} #{other.next}" }
      end
    ]
    letters = ["b b", "d d", "f f", "h h", "j j", "a b d", "d e g", "g h j"]
    Wga::Scripter.add_script script
    assert_equal letters, Wga::Scripter.run('localhost', :test_explode).to_s.split($/)
  end

  def test_run_script
    sc1 = %q[
      script :test_run do
        section "from sc2"
        run :second_script
        run :second_script, :host => "127.0.0.1"
      end
    ]
    sc2 = %q[
      script :second_script do
        sh "whoami"
      end
    ]
    Wga::Scripter.add_script sc1
    Wga::Scripter.add_script sc2
    prompt = "[#{%x(whoami).chomp}@#{%x(hostname).chomp}:~]$ whoami"
    sc_out = ["from sc2", prompt, "goredar", prompt, "goredar"]
    assert_equal sc_out, Wga::Scripter.run('localhost', :test_run).to_s.split($/)
  end

end
