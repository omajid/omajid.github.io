+++
title = "-Wmisleading-indentation in OpenJDK"
date = "Mon, 29 Feb 2016 15:21:27 +0000"
categories = [ "development" ]
aliases = [
    "/2016/02/29/wmisleading-indentation-in-openjdk/",
]
+++
Inspired by [this post by Mark Wielaard](https://gnu.wildebeest.org/blog/mjw/2016/01/09/looking-forward-to-gcc6-nice-new-warnings/) I started wondering how OpenJDK 9 would fare in a `-Wmisleading-indentation` test. So I built OpenJDK 9 using `-Wall` to find out.

First, though, a big heads up: the OpenJDK 9 build selectively enables and
disables warnings and turns on `-Werorr`. There doesn't seem to be a straight-
forward way of enabling all compiler warnings everywhere. I ended up patching
various makefiles to comment out various `DISABLED_WARNINGS* f`lags. Hotspot
needed a separate patch to initialize `WARNING_FLAGS` with `-Wall` in
`hotspot/make/linux/makefiles/gcc.make`. Then I built OpenJDK 9 using:

    mkdir build
    cd build
    bash ../configure --with-extra-cflags="-Wall -Wextra" --with-extra-cxxflags="-Wall -Wextra -fpermissive" --disable-warnings-as-errors

A `grep misleading-indentation build.log` was surprising:

    jdk9-dev/jdk/src/java.base/share/native/libfdlibm/e_asin.c:103:17: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.base/share/native/libfdlibm/k_rem_pio2.c:201:61: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmscgats.c:613:13: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmscgats.c:690:13: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmsintrp.c:959:29: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmsintrp.c:1023:29: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmsio1.c:717:9: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmsopt.c:557:13: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmsopt.c:1021:29: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmsps2.c:1015:9: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmstypes.c:2398:9: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmstypes.c:2679:9: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/liblcms/cmswtpnt.c:109:9: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/libfontmanager/layout/SunLayoutEngine.cpp:154:25: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/libsplashscreen/libpng/pngread.c:3880:16: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
    jdk9-dev/jdk/src/java.desktop/share/native/libsplashscreen/libpng/pngread.c:3997:10: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]

`libfdlibm`, `liblcms` and `libpng` are all external libraries that are
bundled with OpenJDK. In the case of Linux distributions, they are often
replaced with dynamically linked system libraries. That only code that's
actually part of OpenJDK itself is `libfontmanager`.

Let's take a look at that. The warning itself is:

    /home/omajid/jdk9-dev/jdk/src/java.desktop/share/native/libfontmanager/layout/SunLayoutEngine.cpp:154:25: warning: statement is indented as if it were guarded by... [-Wmisleading-indentation]
       if (min < 0) min = 0; if (max < min) max = min; /* defensive coding */
                             ^~
    /home/omajid/jdk9-dev/jdk/src/java.desktop/share/native/libfontmanager/layout/SunLayoutEngine.cpp:154:3: note: ...this 'if' clause, but it is not
       if (min < 0) min = 0; if (max < min) max = min; /* defensive coding */
       ^~

So gcc thinks the programmer meant to guard the second `if` statement with the
first but failed to do so. But a quick look at the code suggests that these
are indeed two independent checks - one checks and fixes `min` and the other
fixes `max`. The developer just tried to save whitespace and write them in one
line. Definitely a false postive.

Anyway, I am impressed with OpenJDK's code quality: gcc doesn't find any
actual misleading indentation issues in OpenJDK.
