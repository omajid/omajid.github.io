+++
title = "IcedTea-Web and OpenJDK"
date = "Fri, 24 Jan 2014 00:29:36 +0000"
author = "Omair Majid"
tags = [ "icedtea-web", "openjdk" ]
aliases = [
    "/2014/01/23/icedtea-web-and-openjdk/",
]
+++
I posted 3 patches today

The [first patch](http://mail.openjdk.java.net/pipermail/jdk9-dev/2014-January/000320.html) is for OpenJDK 9. It creates a hole that allows alternative plugin implementations to plug into (pardon the pun) OpenJDK and make use of existing plugin-specific classes in OpenJDK.

The [second](http://mail.openjdk.java.net/pipermail/distro-pkg-dev/2014-January/025972.html) and [third](http://mail.openjdk.java.net/pipermail/distro-pkg-dev/2014-January/025993.html) patches are for IcedTea-Web. They allow IcedTea-Web to (progressively) build against OpenJDK8 and OpenJDK9.

What does this mean? Soon we might actually be able to build and run IcedTea-
Web against OpenJDK. Yes, an Open Source/Free Software plugin running on top
of OpenJDK (without any custom patches). Of course, a lot of this is still up
in the air. The OpenJDK folks might not accept the patch, though I am hopeful
they will - it's very small and conservative.

Fun times ahead!


