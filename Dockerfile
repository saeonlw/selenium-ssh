FROM ubuntu:18.04

LABEL authors="Yon <yon.liu@aliyun.com>"

#========================================
# Customize sources for apt-get
#========================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu bionic main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu bionic-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================================
# get java/ssh/selenium
#========================================
RUN apt-get -qqy update \
    && apt-get -qqy install net-tools network-manager tzdata openssh-server \
    && service ssh start

RUN apt-get -qqy install openjdk-8-jre-headless \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' \
    ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

RUN wget --no-verbose \
    https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar \
    -O $HOME/selenium-server-standalone.jar


#========================================
# Timezone settings. Possible alternative:
# https://github.com/docker/docker/issues/3359#issuecomment-32150214
#========================================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata


#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd seluser \
         --shell /bin/bash  \
         --create-home \
  && usermod -a -G sudo seluser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'seluser:secret' | chpasswd

ENV HOME=/home/seluser


#========================================
# ssh config
#========================================
ENV IP_ADDRESS ""
#RUN cd $HOME && IP_ADDRESS=$(./getip.sh|grep "IP ADDRESS"|awk -F: '{print $2}') \
#    && echo $IP_ADDRESS
#RUN cd $HOME && DNS_ADDRESS=$(./getip.sh|grep "DNS ADDRESS"|awk -F: '{print $2}')
COPY getip.sh $HOME/
RUN chmod +x $HOME/getip.sh

USER seluser

# dsa, ecdsa, ed25519, rsa
ENV SSH_KEY=""
ARG KEY_TYPE=rsa
RUN ssh-keygen -t $KEY_TYPE -f "$HOME/.ssh/id_$KEY_TYPE" -P ""
RUN SSH_KEY=$(cat ~/.ssh/id_rsa.pub)&& echo $SSH_KEY
EXPOSE 22


#========================================
# selenium config.
# CONFIG_JSON_NAME for customize file in
# $HOME.
# CONFIG_JSON for whole customize file
# path
#========================================

# place the json file to location where `-v`
# pointing before building
ENV CONFIG_JSON_NAME ""
ENV CONFIG_JSON $HOME/$CONFIG_JSON_NAME

RUN echo $(java -version)

#========================================
# container
#========================================
ENV LOCAL_IP_ADDRESS ""
CMD cd $HOME && LOCAL_IP_ADDRESS=$(./getip.sh|grep "IP ADDRESS"|awk -F: '{print $2}') && echo $LOCAL_IP_ADDRESS
CMD java -jar $HOME/selenium-server-standalone.jar -role node -nodeConfig $CONFIG_JSON

