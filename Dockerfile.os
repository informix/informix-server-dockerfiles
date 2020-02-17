FROM registry.access.redhat.com/ubi7/ubi-minimal:latest 
LABEL maintainer=darin.tracy@hcl.com 



RUN microdnf -y install wget
# Add CentOS repo
COPY ./centos.repo /etc/yum.repos.d/

RUN wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
     microdnf install -y \
        shadow-utils            \     
        which sudo tar gzip \     
        libaio                    \     
        # libaio1 - not avail  \     
        # libncurses5 - not avail \
        ncurses-devel    \     
        hostname && \      
    groupadd informix -g 200 && \
    useradd -m -g informix -u 200 informix  -s /bin/bash && \
    useradd -m  guest -s /bin/bash && \
    rm -rf /var/cache/yum/* && \
    echo "informix ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "informix:in4mix" | chpasswd







