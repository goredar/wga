description "Show disk space utilization"
pattern /Low disk space \(<(\d+)%\) on volume (.+)/

script :low_disk do |args = {}|

  section "Overall Status"
  sh "sudo df -Ph | grep --color=never -E '^(/dev/)|(Filesystem)'"

  level, volume = *args[:match]
  level ||= 9
  problem_volumes = {}

  if volume
    sh "sudo df -PB1 | grep -E '^/dev/'" do |out|
      explode(out) { |filesystem, size, used, avail, use_p, mounted| problem_volumes[volume] = size.to_i if mounted == volume }
    end
  else
    sh "sudo df -PB1 | grep -E '^/dev/'" do |out|
      explode out do |filesystem, size, used, avail, use_p, mounted|
        next if use_p.to_i < 100 - level.to_i
        problem_volumes[mounted] = size.to_i
      end
    end
  end

  problem_volumes.each do |volume, volume_size|
    section "Top 30 directories and files on volume #{volume}"
    # "sudo du -aPB1 --max-depth=5 --one-file-system --time --time-style='+%d-%m-%y %R' #{volume} 2>&- | sort -rn | head -30"
    sh "sudo du -aPB1 --max-depth=5 --one-file-system --time --time-style='+%d-%m-%y %R' #{volume} 2>&- | sort -rn | head -n30" do |out|
      dir_stack = []
      code do
        prompt("sudo du -aPB1 --max-depth=5 #{volume} 2>&- | sort -rn | head -n30") +
        explode(out, :columns => 4) do |size, mdate, mtime, dir_name|
          until dir_stack.empty?
            dir_name.include?(dir_stack.last + "/") ? break : dir_stack.pop
          end
          dir_stack.push dir_name
          "#{mdate} #{mtime}\t#{size.to_i * 100 / volume_size}%\t#{to_pretty_size size}\t#{'  ' * (dir_stack.size - 1) + dir_name}"
        end
      end
    end
    section "Unlinked files"
    sh "sudo lsof +aL1 #{volume} 2>&- | grep deleted |  sort -rnk7 | head -n30" do |line|
      code do
        prompt("sudo lsof +aL1 #{volume} 2>&- | grep deleted |  sort -rnk7 | head -n30") + 
          explode(line) { |*pieces| pieces[6] = to_pretty_size pieces[6]; pieces.join("\t") }
      end
    end
  end
end