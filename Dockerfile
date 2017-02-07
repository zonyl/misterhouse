FROM perl:5.20
COPY . /usr/src/misterhouse
WORKDIR /usr/src/misterhouse
CMD [ "perl", "./bin/mh" ]
EXPOSE 8080
