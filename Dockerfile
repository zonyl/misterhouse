FROM phusion/baseimage
LABEL maintainer "Jason Sharpee <jason@sharpee.com>"

EXPOSE 8080
ENV mh_parms=/usr/src/misterhouse/local/mh.private.ini
VOLUME ['/usr/src/misterhouse/local']

RUN [ "apt-get", "-q", "update" ]
RUN [ "apt-get", "-qy", "--force-yes", "upgrade" ]
RUN [ "apt-get", "-qy", "--force-yes", "dist-upgrade" ]
RUN [ "apt-get", "install", "-qy", "--force-yes", \
      "perl", \
      "build-essential", \
      "cpanminus" ]
RUN [ "apt-get", "clean" ]
RUN [ "rm", "-rf", "/var/lib/apt/lists/*", "/tmp/*", "/var/tmp/*" ]

COPY . /usr/src/misterhouse
WORKDIR /usr/src/misterhouse/bin
CMD [ "perl", "./mh" ]
