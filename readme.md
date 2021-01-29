# FreeRADIUS w/ NTLM

This project provides the source for a FreeRADIUS container to bind to your domain, with the added benefit of optionally talking to eduroam.

A couple of notes:
* This is still very much a work in progress. Expect breaking changes on the master branch.
* _I want to be the first to say, yes, this is weird. This container binds itself to your AD domain with winbind. It's as peculiar for me to say as you to think. But it works, and it works quite swell._

## Setup / Implementation

### Docker Implemenation

Please see the [docker](docs/docker.md) notes under docs for more details.

### Kubernetes

A simple helm chart has been made for consuming this for Kubernetes. Please read the chart's [README](charts/freeradius/README.md) for more details.

### VM / Physical Install

If you want to use a VM instead of a container, you can probably take the reverse the `Dockerfile` and the `init.sh` script in this repository and modify it to work on a VM. I will not be providing actual documentation for this though.

### Logging / Monitoring

#### Prometheus

[IPification](https://github.com/bvantagelimited) has built a prometheus exporter for FreeRADIUS. This queries the status module to gather that information. ESU2 has packaged this as a docker image [here](https://hub.docker.com/r/esutwo/freeradius-exporter). You can use this to extract metrics from your FreeRADIUS server. Please see the Docker and Kubernetes docs included in this repo for how to use this.

#### FileBeat Logging

Many default configs have been edited in this container in order to supply some useful logs to be processed by FileBeat / Logstash. More details about logging setup can be found here: [docs/logging.md](docs/logging.md)

## Based off the following projects:

* [Docker-Samba-Join-AD](https://github.com/fjudith/docker-samba-join-ad/)
* [FreeRADIUS AD Setup](https://xenomorph.net/linux/ubuntu/misc/radius-unifi/)
* [FreeRADIUS eduroam Setup](https://wiki.freeradius.org/guide/eduroam)
* [FreeRADIUS eduroam Logging](https://wiki.freeradius.org/guide/eduroam-logging)
* [FreeRADIUS Logging Config](https://www.slideshare.net/MatthewNewton28/freeradius-eduroam-logging-and-elasticsearch)
* [FreeRADIUS Prometheus Metrics](https://github.com/bvantagelimited/freeradius_exporter)
