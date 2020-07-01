#!/bin/bash
#Script Developed by Abhishek Mahadik
#Checking whether user has enough permission to run this script

sudo -n true
if [ $? -ne 0 ]
    then
        echo "This script requires user to have passwordless sudo access"
        exit
fi

dependency_check_rpm() {
    java -version
    if [ $? -ne 0 ]
        then
        #Installing Java 8 if it's not installed
            sudo yum install jre-1.8.0-openjdk -y
        # Checking if java installed is less than version 7. If yes, installing Java 8. As logstash & Elasticsearch require Java 7 or later.
        elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
            then
                sudo yum install jre-1.8.0-openjdk -y
    fi
}

rpm_elk() {
    #Installing wget.
    sudo yum install wget -y
	#Installing locate functionality
	sudo yum install mlocate
	sudo updatedb
	#Download and install the public signing key
	sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    # Downloading rpm package of logstash
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/logstash/logstash-7.8.0.rpm
    # Install logstash rpm package
    sudo rpm -ivh /opt/logstash-7.8.0.rpm
	sudo /usr/share/logstash/bin/system-install /etc/logstash/startup.options systemd
	sudo systemctl start logstash.service
	sudo -u logstash /usr/share/logstash/bin/logstash-plugin install logstash-filter-date_formatter
	sudo -u logstash /usr/share/logstash/bin/logstash-plugin install logstash-input-file
    # Downloading rpm package of elasticsearch
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-x86_64.rpm	
    # Install rpm package of elasticsearch
    sudo rpm -ivh /opt/elasticsearch-7.8.0-x86_64.rpm
	sudo /bin/systemctl daemon-reload
	sudo /bin/systemctl enable elasticsearch.service
	sudo systemctl start elasticsearch.service
    # Downloading rpm package of Kibana in /opt
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/kibana/kibana-7.8.0-x86_64.rpm
    # Install rpm package of kibana
    sudo rpm -ivh /opt/kibana-7.8.0-x86_64.rpm
	sudo /bin/systemctl daemon-reload
	sudo /bin/systemctl enable kibana.service
	sudo systemctl start kibana.service	
}

configure_kibana_yml()
{
    local KIBANA_CONF=/etc/kibana/kibana.yml
    # backup the current config
    mv $KIBANA_CONF $KIBANA_CONF.bak
    # set the elasticsearch URL
    echo "server.port: 5601" >> $KIBANA_CONF
    echo "server.host: \"$(ip addr |grep -v "127.0.0.1" |grep "inet "|awk -F " " '{print $2}'|awk -F "/" '{print $1}')"\" >> $KIBANA_CONF
    echo "elasticsearch.hosts: [\"http://$(ip addr |grep -v "127.0.0.1" |grep "inet "|awk -F " " '{print $2}'|awk -F "/" '{print $1}'):9200\"]" >> $KIBANA_CONF
    #specify kibana log location
    echo "logging.dest: /var/log/zeroELK.log" >> $KIBANA_CONF
    touch /var/log/zeroELK.log
    chown kibana: /var/log/zeroELK.log
    # set logging to quiet by default. Note that kibana does not have
    # a log file rotation policy, so the log file should be monitored
    echo "logging.quiet: true" >> $KIBANA_CONF
    echo "xpack.security.enabled: true" >> $KIBANA_CONF
    echo "xpack.security.audit.enabled: true" >> $KIBANA_CONF
    echo "configuring username as kibana"
    echo "elasticsearch.username: \"kibana"\" >> $KIBANA_CONF
	echo "---------------------------------------------------------------"
    echo "---------------------------------------------------------------"
    echo -n "please enter kibana password configured earlier :"  
    read -s kbpass
    echo "elasticsearch.password: \"$kbpass\"" >> $KIBANA_CONF
    sudo systemctl start kibana.service
}

configure_elasticsearch_yml()
{   
    sudo systemctl stop elasticsearch.service
    sudo systemctl stop kibana.service
    local ES_CONF=/etc/elasticsearch/elasticsearch.yml
    # Backup the current Elasticsearch configuration file
    mv $ES_CONF $ES_CONF.bak
    # Set cluster and machine names - just use hostname for our node.name
    echo "cluster.name: zeroELK" >> $ES_CONF
    echo "http.port: 9200" >> $ES_CONF
    echo "network.host: 0.0.0.0" >> $ES_CONF
    echo "discovery.zen.ping.unicast.hosts: ["$(ip addr |grep -v "127.0.0.1" |grep "inet "|awk -F " " '{print $2}'|awk -F "/" '{print $1}'):9300,0.0.0.0:9300"]" >> $ES_CONF
    # put log files on the OS disk in a writable location
    echo "path.logs: /var/log/elasticsearch" >> $ES_CONF
    echo "path.data: /var/lib/elasticsearch" >> $ES_CONF
    echo "xpack.security.enabled: true" >> $ES_CONF
    echo "xpack.security.transport.ssl.enabled: true" >> $ES_CONF
    echo "Create a Secure Password That You Can Remember Later"
    sudo systemctl start elasticsearch.service
    sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
    sudo systemctl restart elasticsearch.service
}

check_services()
{  
   echo "CHECK STATUS of ELK STACK!!"
   sudo systemctl status logstash.service
   sudo systemctl status elasticsearch.service
   sudo systemctl status kibana.service
   echo "Firewall Configuration Script"
   echo "---------------------------------------------------------------"
   echo "---------------------------------------------------------------"
   echo "Enable access to elasticsearch"
   sudo firewall-cmd --add-port=9200/tcp --permanent
   echo "Enable access to kibana"
   sudo  firewall-cmd --add-port=5601/tcp --permanent
   echo "Enable access to recieve logs on the 5514 TCP\UDP Port"
   sudo firewall-cmd --add-port=5514/tcp --permanent
   sudo firewall-cmd --add-port=5514/udp --permanent
   #UDP Rule
   sudo firewall-cmd --add-forward-port=port=514:proto=udp:toport=5514:toaddr=127.0.0.1 --permanent
   #TCP Rule
   sudo firewall-cmd --add-forward-port=port=514:proto=tcp:toport=5514:toaddr=127.0.0.1 --permanent
   sudo firewall-cmd --complete-reload
   sudo systemctl restart firewalld 
   echo "---------------------------------------------------------------"
   echo "---------------------------------------------------------------"
   echo " Your Turn: Finish Configuration"
   echo " elasticsearch URL: [\"http://$(ip addr |grep -v "127.0.0.1" |grep "inet "|awk -F " " '{print $2}'|awk -F "/" '{print $1}'):9200\"]"
   echo " Kibana URL: [\"http://$(ip addr |grep -v "127.0.0.1" |grep "inet "|awk -F " " '{print $2}'|awk -F "/" '{print $1}'):5601\"]"
   echo " Please use elastic user and configured password to login to kibana"
   echo "---------------------------------------------------------------"
   echo "---------------------------------------------------------------"
   echo "--------------------END OF INSTALLER---------------------------"
   echo "---------------------------------------------------------------"
   echo "---------------------------------------------------------------"
}

# Installing ELK Stack
if [ "$(grep -Ei 'fedora|redhat|centos' /etc/*release)" ]
    then
        echo "It's a RedHat based system."
        dependency_check_rpm
        rpm_elk
        configure_elasticsearch_yml
	configure_kibana_yml
	check_services
else
    echo "This script doesn't support ELK installation on this OS."
fi
