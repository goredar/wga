CONF = {}
CONF[:wga] = {}
CONF[:wga][:ssh_user] = %x(whoami).chomp
CONF[:wga][:ssh_port] = '22'