+++
title = "OpenJDK6 B28 Released"
date = "Fri, 04 Oct 2013 17:51:36 +0000"
author = "Omair Majid"
aliases = [
    "/2013/10/04/openjdk6-b28-released/",
]
+++
On October 4, 2013, the [OpenJDK6 b28 source bundle](https://java.net/projects/openjdk6/downloads/download/openjdk-6-src-b28-04_oct_2013.tar.gz "OpenJDK6 b28") was published at <https://java.net/projects/openjdk6/downloads/>.

This includes all the security patches since the b27 release as well as [a major version bump in hotspot to hs23](http://mail.openjdk.java.net/pipermail/jdk6-dev/2013-September/003039.html). A [complete list of changes is available](https://openjdk6.java.net/OpenJDK6-B28-Changes.html) too.

The test results were not ideal.

The TCK failed, with all issues basically boiling down to limited cryptography support. There are [patches available to fix this](http://mail.openjdk.java.net/pipermail/security-dev/2008-August/000283.html). As far as I can tell this is not a regression.

The jtreg tests did not pass cleanly either. Most of the failures were caused
by tests trying to access "javaweb.sfbay.sun.com", which is not accessible
(from outside Oracle?). Some issues were caused by tests having a `@build` tag
but no `@run` tag (perhaps older jtreg versions were more lenient). Two new
tests, introduced by the 2013-04-16 security update,
`java/beans/Introspector/7064279/Test7064279.java` and
`java/beans/Introspector/Test5102804.java` both failed.

A special thanks to Andrew Hughes for all his contributions (especially with
the hotspot 23 backport) and to Pavel Tisnovsky for testing.

Onwards to B29!


