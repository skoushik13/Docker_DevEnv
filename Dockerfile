FROM ubuntu:16.04 

MAINTAINER Koushik Anagurthi

ENV LANG C.UTF-8
ARG SCALA_VERSION=2.11.8
ARG SBT_VERSION=1.0.3
ARG INTELLIJ_VERSION=2017.2.6
ARG USER_NAME=dev
ARG OPENJDK_VERSION=8

USER root
# Use baseimage-docker's init system.
#CMD ["/sbin/my_init"]

# ...put your own build instructions here...
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

RUN echo 'Installing OS dependencies' && \
  apt-get install -qq -y --fix-missing sudo software-properties-common wget unzip git openssh-server libssl-dev libffi-dev python python-pip python3-setuptools curl apt-transport-https libaio1 python3 python3-dev librabbitmq-dev libpqxx-dev libssl-dev libffi-dev libaio1 python3-crypto python3-lxml unixodbc unixodbc-dev

RUN apt-get install bc

RUN apt-get install apt-utils

RUN easy_install3 pip

RUN pip3 install pytest

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

RUN echo 'Installing openjdk-$OPENJDK_VERSION-jdk' && \
    apt-get install openjdk-$OPENJDK_VERSION-jdk -qq -y && \
    apt-get install gradle -qq -y

RUN \
  curl -L -o sbt-$SBT_VERSION.deb http://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install sbt && \
  sbt sbtVersion

RUN echo 'Cleaning up' && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y &&  \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

#sudo echo "dev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dev && \
#echo "dev: dev" | chpasswd && adduser dev sudo && \
#chown root:root /usr/bin/sudo && \
#chmod 4755 /usr/bin/sudo

RUN echo 'Creating user: dev' && \
    mkdir -p /data/dev && \
    echo "dev:x:1000:1000:dev,,,:/data/dev:/bin/bash" >> /etc/passwd && \
    echo "dev:x:1000:" >> /etc/group && \
    chown dev:dev -R /data/dev
    
	
RUN mkdir -p /data/dev/.IdeaIC$INTELLIJ_VERSION/config/options && \
    mkdir -p /data/dev/.IdeaIC$INTELLIJ_VERSION/config/plugins

ADD ./jdk.table.xml /data/dev/.IdeaIC$INTELLIJ_VERSION/config/options/jdk.table.xml
ADD ./jdk.table.xml /data/dev/.jdk.table.xml

ADD ./pluginSetup /usr/local/bin/intellij

#ADD ./run /usr/local/bin/intellij
#ADD ./idea-sbt-plugin-1.8.0.zip /data/dev/.IdeaIC$INTELLIJ_VERSION/config/plugins/idea-sbt-plugin-1.8.0.zip

RUN chmod +x /usr/local/bin/intellij && \
    chown dev:dev -R /data/dev/.IdeaIC$INTELLIJ_VERSION

RUN echo 'Downloading IntelliJ IDEA' && \
    wget -O /tmp/intellij.tar.gz https://download.jetbrains.com/idea/ideaIC-$INTELLIJ_VERSION.tar.gz && \
    echo 'Installing IntelliJ IDEA' && \
    mkdir -pv /opt/intellij && \
    tar -xf /tmp/intellij.tar.gz --strip-components=1 -C /opt/intellij && \
    rm /tmp/intellij.tar.gz

# RUN echo 'Installing set plugin' && \
#   cd /home/dev/.IdeaIC$INTELLIJ_VERSION/config/plugins/ && \
#    unzip -q idea-sbt-plugin-1.8.0.zip && \
#   rm idea-sbt-plugin-1.8.0.zip
	
RUN echo 'Installing Markdown plugin' && \
    wget -O markdown.zip https://plugins.jetbrains.com/files/7793/25156/markdown-2016.1.20160405.zip && \
    unzip -q markdown.zip && \
    rm markdown.zip

# Download and configure the Scala distribution
ENV SCALA_HOME /usr/local/share/scala
# curl -LO http://www.scala-lang.org/files/archive/scala-$SCALA_VERSION.tgz | tar xfz - -C ~/ && \

RUN echo 'Installing scala plugin' && \
  wget -O /tmp/scala.tar.gz http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz && \
  echo 'Installing Scala' && \
  mkdir -pv $SCALA_HOME && \
  tar -xf /tmp/scala.tar.gz --directory $SCALA_HOME --strip-components=1 && \
  rm /tmp/scala.tar.gz

RUN \
  echo >> ~/.bashrc && \
  echo 'export PATH=$SCALA_HOME/bin:$PATH' >> ~/.bashrc

USER dev
ENV HOME /data/dev
WORKDIR /data/dev
CMD /usr/local/bin/intellij