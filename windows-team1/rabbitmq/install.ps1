echo $env:RABBITMQ_NODENAME
echo $env:RABBITMQ_NODE_IP_ADDRESS
& 'C:\Program Files\rabbitmq_server-3.6.10\sbin\rabbitmq-service.bat' install
& 'C:\Program Files\rabbitmq_server-3.6.10\sbin\rabbitmq-service.bat' start
& 'C:\Program Files\rabbitmq_server-3.6.10\sbin\rabbitmq-service.bat' enable
& 'C:\Program Files\rabbitmq_server-3.6.10\sbin\rabbitmqctl.bat' status
& 'C:\Program Files\rabbitmq_server-3.6.10\sbin\rabbitmq-plugins.bat' enable rabbitmq_management
& 'C:\Program Files\rabbitmq_server-3.6.10\sbin\rabbitmq-plugins.bat' enable rabbitmq_management --offline
