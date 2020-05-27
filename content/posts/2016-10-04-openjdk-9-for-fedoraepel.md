+++
title = "OpenJDK 9 for Fedora/EPEL"
date = "Tue, 04 Oct 2016 23:35:09 +0000"
author = "Omair Majid"
tags = [ "openjdk", "openjdk9" ]
aliases = [
    "/2016/10/04/openjdk-9-for-fedoraepel/",
]
+++
Looking to try out OpenJDK 9? If you didn't know, OpenJDK 9 is going to be the reference implemtation for Java 9 (assuming the pattern for Java 7 and Java 8 continues). Pre-release packages for Fedora 23, 24, 25 and Rawhide as well as RHEL 7 are [available on copr](https://copr.fedoraproject.org/coprs/omajid/openjdk9/):

<https://copr.fedoraproject.org/coprs/omajid/openjdk9/>

Please note that these are not official Fedora (or RHEL) packages. Official
Fedora packages will be proposed and added to Fedora closer to OpenJDK 9's
release.

To install on Fedora:

    # dnf copr enable omajid/openjdk9
    # dnf install java-9-openjdk-devel

To install on RHEL (or CentOS) 7:

    $ wget https://copr.fedorainfracloud.org/coprs/omajid/openjdk9/repo/epel-7/omajid-openjdk9-epel-7.repo
    $ su -
    # cp omajid-openjdk9-epel-7.repo /etc/yum.repos.d/
    # yum install java-9-openjdk-devel

Then use as follows:

    $ /usr/lib/jvm/java-1.9.0-openjdk/bin/java -version

To make it the default Java version, use update-alternatives.

    # update-alternatives --config java
    # update-alternatives --config javac

If you are a user, making 9 the default may not be a great idea - OpenJDK 9 is
in heavy development and lots of things are changing. There are also some
known compatibility issues. On the other hand, if you are a Java developer,
this will give you a good idea of how prepared your favourite libraries and
tools are for Java 9.


