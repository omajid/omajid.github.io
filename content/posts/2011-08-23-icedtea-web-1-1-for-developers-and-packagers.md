+++
title = "What IcedTea-Web 1.1 means for you"
date = "Tue, 23 Aug 2011 18:34:41 +0000"
author = "Omair Majid"
categories = [ "development" ]
tags = [ "icedtea-web", "icedtea-web-1.1" ]
aliases = [
    "/2011/08/23/icedtea-web-1-1-for-developers-and-packagers/",
]
+++
A number of changes occurred between IcedTea-Web 1.0 and IcedTea-Web 1.1. If
you are a packager or a developer here are some things you need to know.

## Are you a packager?

IcedTea-Web 1.1 can be installed into a regular prefix (`/usr/` or
`/usr/local/` or anything else). Unlike IcedTea-Web 1.0, you do not need to
install IcedTea-Web into a JDK or JRE directory. IcedTea-Web uses a JDK to
build itself (specified using `--with-jdk-home`). IcedTea-Web will use the JDK
it was compiled against to run. The launchers (`javaws` and `itweb-settings`)
are now shell scripts and can be customized as needed.

## Are you a developer using applets or java web start?

IcedTea-Web 1.1 provides `netscape.javascript.*` and `javax.jnlp.*` classes
that applets and web start applications use. However, unlike icedtea-web < 1.1
(or older releases of icedtea6) the jars that provide these classes will not
be automatically be picked up by the JDK. `netscape.javascript.*` classes are
included in IcedTea-Web's `plugin.jar`. `javax.jnlp.*` classes are included in
IcedTea-Web's `netx.jar`. Please add these classes to your classpath when
building.


