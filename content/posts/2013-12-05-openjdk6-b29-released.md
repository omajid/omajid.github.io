+++
title = "OpenJDK6 B29 Released!"
date = "Fri, 06 Dec 2013 02:50:16 +0000"
author = "Omair Majid"
aliases = [
    "/2013/12/05/openjdk6-b29-released/",
]
+++
On December 5, 2013, the [OpenJDK6 b29 source bundle](https://java.net/projects/openjdk6/downloads/download/openjdk-6-src-b29-05_dec_2013.tar.gz "OpenJDK6 b29") was published at <https://java.net/projects/openjdk6/downloads/>.  
  
This is a security bugfix release that includes all the security patches since the b28 release. A [complete list of changes is available](https://openjdk6.java.net/OpenJDK6-B29-Changes.html) too.  
  
The test results were not ideal.  
  
The TCK failed, with all issues again basically boiling down to limited cryptography support. There are [patches available to fix this](http://mail.openjdk.java.net/pipermail/security-dev/2008-August/000283.html). As far as I can tell this is not a regression.   
  
The jtreg tests did not pass cleanly either.  
  
A special thanks to [Andrew Hughes](http://blog.fuseyism.com/) for backporting all the security fixes to OpenJDK6.  
  
Onwards to B30!


