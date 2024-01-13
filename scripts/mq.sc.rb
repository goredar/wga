description "RabbitMQ queues diagnostic"
pattern /RabbitMQ/

script :mq do |args = {}|

  section "RabbitMQ queues (No consumers or non zero queue)"
  sh "for vhost in $(sudo rabbitmqctl list_vhosts | egrep -v '(^L|^/$|done.$)'); do ( echo $vhost; sudo rabbitmqctl list_queues consumers messages name -p $vhost | awk '{ if ( $1 == 0 || $2 != 0 ) print $0 }' | egrep -v '(^L|^/$|done.$)' | sort -rnk 2 ); done"

  # add TCP Port check
end
