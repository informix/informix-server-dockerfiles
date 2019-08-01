FROM debian:jessie
#FROM debian:stretch

MAINTAINER darin.tracy@hcl.com 

RUN apt-get update -qy

RUN groupadd informix -g 200
RUN useradd -m -g informix -u 200 informix  -s /bin/bash


RUN apt-get -y install net-tools
RUN apt-get -y install libaio1 bc libncurses5 ncurses-bin libpam0g 
RUN apt-get -y install libncurses5-dev libelf1
#RUN apt-get -y install openssh-server
RUN apt-get -y install vim
RUN apt-get -y install sudo
RUN apt-get -y install curl
RUN apt-get -y install jq 


#RUN apt-get install -y openjdk-7-jre 
#RUN apt-get -y install openjdk-8-jdk


RUN  echo "informix ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN  echo "informix:in4mix" | chpasswd





