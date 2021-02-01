# Logging

In order to provide valuable logs, the default FreeRADIUS configuration has been overridden in several spots, in addition to a re-write of the linelog module for JSON output, which in turn is easier to ingest with filebeat.

A sample `filebeat.yml` configuration file has also been provided, in addition to an example docker-compose configuration.

## FreeRADIUS Changes for linelog

First and foremost, I have modified the Outer-Tunnel `User` attribute to be overridden by the Inner-Tunnel `User` attribute. Beyond this, all I have added are additional statements throughout the config to increase log output, or add additional attributes.

As for the changes in linelog, the JSON formatting was inspired / taken from [here](http://freeradius.1045715.n5.nabble.com/auth-and-detail-logs-into-json-format-tp5750035p5750041.html). I removed all the attributes I felt were unuseful to me, and added a few of my own to the mix. _I would highly recommend modifying these so they include any additional vendor attributes you would like!_

## Filebeat Configuration

A filebeat configuration can be located here: [configs/filebeat.yml](configs/filebeat.yml)

Most notable about this, is it expects an environment variable pointing to the logstash host you are sending it too. Additionally, a processor is provided to separate out the user and domain in an email address. This is useful with eduroam and wanting to look at logs about which domains are most popular on your network.

### Docker-Compose

Provided below is the sample docker-compose configuration for filebeat.

```yaml
version: '3.7'
services:
...
  filebeat:
    image: docker.elastic.co/beats/filebeat-oss:6.8.13
    environment:
      LOGSTASH_HOST: graylog.example.com:5044
    volumes:
      - ./configs/filebeat.yml:/usr/share/filebeat/filebeat.yml
      - ./logs:/var/log/freeradius:ro
      - filebeat-data:/usr/share/filebeat/data
    network_mode: service:eduroam-radius

volumes:
  filebeat-data:
```
