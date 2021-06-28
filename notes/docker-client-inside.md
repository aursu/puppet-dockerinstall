

docker run -ti --rm -v /etc/docker/tls:/root/.docker --add-host=build38.intern.crytek.de:192.168.7.18 -e DOCKER_HOST=tcp://build38.intern.crytek.de:2376 -e DOCKER_TLS_VERIFY=1 centos:7 /bin/bash


yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce docker-ce-cli containerd.io