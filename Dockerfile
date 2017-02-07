FROM perl:5.20
LABEL maintainer "Jason Sharpee <jason@sharpee.com>"

EXPOSE 8080
ENV mh_parms=/usr/src/misterhouse/local/mh.private.ini
VOLUME ['/usr/src/misterhouse/local']

COPY . /usr/src/misterhouse
WORKDIR /usr/src/misterhouse
CMD [ "perl", "./bin/mh" ]
