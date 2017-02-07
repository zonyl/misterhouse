MisterHouse
===========

[![Build Status](https://travis-ci.org/hollie/misterhouse.svg?branch=master)](https://travis-ci.org/hollie/misterhouse)

Perl open source home automation program. It's fun, it's free, and it's entirely geeky.

* [Quickstart Guide](https://github.com/hollie/misterhouse/wiki/Getting-started)
* [Standard Installation Guide](http://misterhouse.sourceforge.net/install.html)
* [User Wiki](https://github.com/hollie/misterhouse/wiki)
* [User Mail List misterhouse-users](https://sourceforge.net/p/misterhouse/mailman/misterhouse-users/)

* Active Development Repository - [GitHub hollie/misterhouse](https://github.com/hollie/misterhouse)


Docker
======

Normal Execution:
docker run -P -v /c/Projects/mh/local:/usr/src/misterhouse/local -t -i zonyl/misterhouse

Bash Shell:
docker run -v /c/Projects/mh/local:/usr/src/misterhouse/local -t -i zonyl/misterhouse /sbin/my_init -- bash -l

