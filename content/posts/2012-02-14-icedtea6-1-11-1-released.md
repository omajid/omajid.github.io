+++
title = "IcedTea6 1.11.1 Released!"
date = "Tue, 14 Feb 2012 21:46:43 +0000"
author = "Omair Majid"
aliases = [
    "/2012/02/14/icedtea6-1-11-1-released/",
]
+++
A new release of IcedTea6 1.11 branch is now available: [1.11.1](http://icedtea.classpath.org/download/source/icedtea6-1.11.1.tar.gz)  
  
The update contains the following security fixes:  
  
\- S7082299, CVE-2011-3571: Fix in AtomicReferenceArray  
\- S7088367, CVE-2011-3563: Fix issues in java sound  
\- S7110683, CVE-2012-0502: Issues with some KeyboardFocusManager method  
\- S7110687, CVE-2012-0503: Issues with TimeZone class  
\- S7110700, CVE-2012-0505: Enhance exception throwing mechanism in  
ObjectStreamClass  
\- S7110704, CVE-2012-0506: Issues with some method in corba  
\- S7112642, CVE-2012-0497: Incorrect checking for graphics rendering  
object  
\- S7118283, CVE-2012-0501: Better input parameter checking in zip file  
processing  
\- S7126960, CVE-2011-5035: (httpserver) Add property to limit number  
of request headers to the HTTP Server  
  
This release also contains the following additional fix:  
\- PR865: Patching fails with patches/ecj/jaxws-getdtdtype.patch  
  
The tarball can be downloaded from:  
http://icedtea.classpath.org/download/source/icedtea6-1.11.1.tar.gz  
  
SHA256SUM:  
bafb0e21e1edf5ee22871b13dbc0a8a0d3efd894551fb91d5f59783069b6912c  
  
A signature (produced using my public key) is available at:  
http://icedtea.classpath.org/download/source/icedtea6-1.11.1.tar.gz.sig  
  
The following people helped with this release:  
  
* Andrew Haley  
* Andrew John Hughes  
* Chris Phillips  
* Danesh Dadachanji  
* Deepak Bhole  
* Jiri Vanek  
* Omair Majid  
* Roman Kennke  
  
A huge thanks to everyone who helped test this release and reported bugs!  
  
To get started:  
$ tar xf icedtea6-1.11.1.tar.gz  
$ cd icedtea6-1.11.1  
  
Full build requirements and instructions are in INSTALL:  
$ ./configure [--enable-zero --enable-pulse-java --enable-systemtap ...]  
$ make  


