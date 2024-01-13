# Wga

W Automation tool (WGA)

Tries to automate routine task and provide scripts for diagnostic.

## Installation

Install ruby and build tools(make, gcc, etc) and curl development package with appropriate pakage manager
```
[install ruby]
[install build tools]
[install libcurl-dev]
```
Install MongoDB, start and enable service
```
[install mongo]
sudo systemctl enable mongodb.service
sudo systemctl start mongodb.service
```
Change your PATH environment variable to include gem's bin directory, add to your ~/.bashrc file:
```
if which ruby >/dev/null && which gem >/dev/null; then
    PATH="$PATH:$(ruby -rubygems -e 'puts Gem.user_dir')/bin"
fi
```
Install wga gem
```
gem install wga --user-install
```
Install default config and scripts
```
wga --install
```
Change username and password settings
```
vim ~/.config/l1.conf
```
Populate wgh database
```
wgh -u
```
Use it!

## Update
Don't foget to update regularly
```
# update gems
gem update wga wgz wgh
# update cmdb and clusters
wgh -u
# update scripts
wga -u
```

## Usage

List avaliable scripts
```
wga -l
```
Run script manually
```
wga -s free_ram localhost
```
Pass zabbix triggers and print output to console
```
wgz mq | wga
wgz -h hostname | wga
```
Run appropriate scripts, create issue (jira), post diagnostic info to issue
```
wgz issue | wga -i
```
and acknowledge triggers in zabbix
```
wgz issue | wga -i --ack
```
Try to fix issue (if script has appropriate commands)
```
wgz loginapps | wga --fix
wgz tungsten | wga -f
```
Get info about hosts in zabbix dashbord
```
wgz mq | wgh
```
Get and filter triggers using info from cmdb and process them in wga
```
wgz puppet | wgh -o WDO | wga -i --ack
```
See help for all avaliable options
```
wga --help
```

## Bugs, issues, feature requests and other suggestion

In case of any error try to run with --debug option and post as many details as possible.
