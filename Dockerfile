FROM node:alpine

LABEL gocd.version="17.8.0" \
  description="GoCD agent based on alpine version 3.5" \
  maintainer="GoCD <go-cd-dev@googlegroups.com>" \
  gocd.full.version="17.8.0-5147" \
  gocd.git.sha="53fdb1b15184f93966059a42429bf9ed0bfdee59"

ADD https://download.gocd.org/binaries/17.8.0-5277/generic/go-agent-17.8.0-5277.zip /tmp/go-agent.zip
ADD https://github.com/krallin/tini/releases/download/v0.15.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 /usr/local/sbin/gosu
ADD https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip /tmp/sonar-scanner.zip

# allow mounting ssh keys, dotfiles, and the go server config and data
VOLUME /godata

# force encoding
ENV LANG=en_US.utf8

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  addgroup -g 1001 go && \ 
  adduser -D -u 1001 -G go go && \
  apk --update-cache upgrade && \ 
  apk add --update-cache openjdk8-jre-base git mercurial subversion openssh-client bash && \
# unzip the zip file into /go-agent, after stripping the first path prefix
  unzip /tmp/go-agent.zip -d / && \
  mv go-agent-17.8.0 /go-agent && \
  rm /tmp/go-agent.zip && \
  unzip /tmp/sonar-scanner.zip -d / && \
# use existing jre not the embedded one
  sed -i '/use_embedded_jre=true/d' /sonar-scanner-3.0.3.778-linux/bin/sonar-scanner

ENV PATH="/sonar-scanner-3.0.3.778-linux/bin:${PATH}"

ADD docker-entrypoint.sh /

RUN ["chmod", "+x", "/docker-entrypoint.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]
