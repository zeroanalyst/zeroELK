# zeroELK
zeroELK is a script that will install ELK stack 7.8 on the RedHat based system. 


# Prerequisites
- RPM-based Linux distributions such as RedHat, Centos, Fedora etc. are supported.
- TCP/IP protocol support - recommended to have a static IP set for your system.
- Must be able to elevate to root privileges
- Intel x86 or compatible processor 
- Minimum of 8 GB RAM 
- Minimum of 40 GB hard drive space

# How To Use
1. copy and navigate to folder to run zeroELK script
```sh
#git clone https://github.com/zeroanalyst/zeroELK.git && cd zeroELK
```
2. make zeroELK file executable 
```sh
#sudo chmod +x zeroELK.sh
```
3. run zeroELK
```sh
#sudo ./zeroELK.sh
```
4. check status of installation
```sh
#curl -v SERVERIP:9200
{
  "name" : "HOSTNAME",
  "cluster_name" : "zeroELK",
  "cluster_uuid" : "tgd79-MmTLWh2AedCR4nfw",
  "version" : {
    "number" : "7.8.0",
    "build_flavor" : "default",
    "build_type" : "rpm",
    "build_hash" : "757314695644ea9a1dc2fecd26d1a43856725e65",
    "build_date" : "2020-06-14T19:35:50.234439Z",
    "build_snapshot" : false,
    "lucene_version" : "8.5.1",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}

# curl -v SERVERIP:5601
* About to connect() to SERVERIP port 5601 (#0)
*   Trying SERVERIP...
* Connected to SERVERIP (SERVERIP) port 5601 (#0)
> GET / HTTP/1.1
> User-Agent: curl/7.29.0
> Host: SERVERIP:5601
> Accept: */*
```
5. stop firewalld service to access kibana over the LAN Network.
```sh
#service firewalld stop
```
6. your turn
```sh
elasticsearch URL: "http://SERVERIP:9200"
Kibana URL: "http://SERVERIP:5601"
```

Fore more detailed information on ELK, Please visit the elastic configuration guides:
- Elasticsearch -  <https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html>
- Kibana - <https://www.elastic.co/guide/en/kibana/current/index.html>
- Logstash - <https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html>

