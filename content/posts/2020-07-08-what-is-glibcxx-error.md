+++
title = "What is this GLIBCXX error?"
date = "2020-07-08T20:06:54-04:00"
categories = [ "linux" ]
tags = [ "linux", "tools", "glibc" ]
+++

If you use enterprise or stable Linux distributions, sooner or later
you will see an error like this:

```text
app: /lib64/libc.so.6: version `GLIBC_3.1.45' not found (required by ./app)
```

Or like this:

```text
app: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.20' not found (required by ./app)
```

The application (or library) itself will vary. The path to the `libc`
or `libstdc++` might vary too. But the error will always mention that
a `GLIBCXX` or `GLIBC` version was not found.

What can you do to fix it?

## What are `glibc` and `libstdc++` ?

A little bit of background will help you understand the underlying
issue better (and hopefully fix it).

`glibc` is the [GNU C library](https://www.gnu.org/software/libc/).
It's an implementation of the standard C library. Any program written
in C will use the standard library for things like accessing files and
the network, displaying messages to the user, working with processes
and so on. It's a fundamental component of the operating system.

Hundreds of applications, libraries, and even other non-C programming
languages installed on a typical Linux system will make use of the C
library.

There are other C libraries on Linux too, such as
[`musl`](https://musl.libc.org/), but `glibc` is the most common one.

[`libstdc++`](https://gcc.gnu.org/onlinedocs/libstdc++/) is similar to
`glibc`, but for C++: it's an implementation of the standard library
for C++. Any program written in C++ will use this to implement things
in the C++ libraries. Things like threads, streams, files,
Input/Output and so on.

There is a [great reddit
comment](https://www.reddit.com/r/linuxquestions/comments/1tghjd/what_is_the_relationship_between_gcc_libstdc/ce7rteb/)
that goes into more detail about the relationship between these two
libraries as well as how they relate with other core tools on the
system such as the C compiler (`gcc`) and `binutils`.

An important aspect of a standard library is its **Application Binary
Interface** (or **ABI**). A C program that was written and compiled
against `glibc` in 2010 should continue to work against a new `glibc`
version released in 2020. To make this happen, `glibc` provides an
ABI, and promises to not change that particular ABI. `glibc` can add
additional things, but not change or remove any part of the ABI.
Removing anything in the ABI would break previously compiled
applications.

How can `glibc` improve things if it can not ever change its ABI?

One way `glibc` preserves the ABI but still provides new features is
through the use of symbol versioning. Each symbol, or function,
provided by `glibc` is associated with a version. The linker (`ld`)
links to the function-name-with-the-version. If your C program calls
the function `glob64`, the linker will link it to not just the
`glob64` symbol in `glibc`, but to the fully versioned-symbol
`glob64@GLIBC_2.27`. You can think of the text `glob64@GLIBC_2.27` as
the `glob64` symbol with the version `GLIBC_2.27`.

This feature allows older program to use the older-but-compatible
symbol `glob64@GLIBC_2.2.5` but your new programs to make use of the
newer symbol `glob64@GLIBC_2.27`.

The versions used by `glibc` for symbols generally look like
`GLIBC_<VERSION>`. Some examples are `GLIBC_2.27` and `GLIBC_2.2.5`.

You can find [more information about how symbol versioning works in
`glibc`
here](https://developers.redhat.com/blog/2019/08/01/how-the-gnu-c-library-handles-backward-compatibility/)

`libstdc++` has a similar concept and implementation ABI. In fact,
some versions of `libstdc++` even provide [two different
ABIs](http://allanmcrae.com/2015/06/the-case-of-gcc-5-1-and-the-two-c-abis/)!

The versions exported by `libstdc++` generally look like
`GLIBCXX_<VERSION>`. Some examples: `GLIBCXX_3.4` and `CXXABI_1.3`.

## What does the error mean?

Now that you have a bit of a background on the C and C++ standard
libraries and symbol versions, lets go back to the errors:

```text
app: /lib64/libc.so.6: version `GLIBC_3.1.45' not found (required by ./app)
```

This error happens when the runtime linker tries to load the standard
C library (`libc`) for `app`. The runtime linker sees that `app` has a
dependency on a symbol and the version `GLIBC_3.1.45` is not found in
this C library.

```text
app: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.20' not found (required by ./app)
```

This error happens when the runtime linker tries to load the C++
library (`libstdc++`) for `app`. The runtime linker sees that `app`
has a dependency on a symbol and the version `GLIBCXX_3.4.20` of the
symbol is not found in this C++ library.

In other words, the errors mean that `app` was linked against an newer
version of the C/C++ library. The C/C++ library available on the
system is too old and does not provide those symbols with those
versions.

## How can this happen?

This type of error is easy to run into.

1. You downloaded a pre-built binary compiled for a recent Linux
   distribution and try and run it on an older Linux distribution.

   For example, an application compiled to run on RHEL 8 will show the
   error when run on RHEL 7. So will a [a python package meant to run
   on a newer
   distribution.](https://stackoverflow.com/q/48591455/3561275)

2. You somehow [installed a distribution package meant for a newer
   version of the distribution](https://askubuntu.com/q/1068763).

3. You downloaded an application that just isn't supported on your
   distribution.

   For example, you will run into this if you try and run .NET Core on
   RHEL 5.

The root cause is the same: there's an incompatibility between your
Operating System and the application or library you want to run.

You can check the `GLIBC` or `GLIBCXX` versions needed by an
application or library using `readelf`:

```shell
$ readelf --dyn-syms /usr/bin/java | grep '@GLIBC'
     2: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND __libc_start_main@GLIBC_2.2.5 (3)
     6: 0000000000000000     0 FUNC    WEAK   DEFAULT  UND __cxa_finalize@GLIBC_2.2.5 (3)
```

Here, you can see that this application (`java`) uses two symbols that
are versioned as `GLIBC_2.2.5`.

## How to fix this error?

The correct way to fix this error is to make sure the Linux
distribution you are using is compatible with the application (or
library) that's causing this error.

**The application/library does *not* support your Linux distribution**:

If you are using a Linux distribution which is too old and not
supported by the application, upgrade to a newer one.

For example, if you need to run an application on RHEL 6 that
reports this error, consider upgrading to RHEL 7 (or RHEL 8) to
resolve this problem.

**The application/library does support your Linux distribution**:

If the application/library supports the version of your Linux
distribution, then you got the wrong application or library binary.
See if you can find a binary download that's appropriate for your
distribution. .NET Core, for example, supports RHEL 6, but has a
separate binary download for RHEL 6. The regular .NET download
supports Linux distributions that are newer than RHEL 6.

You might also want to file a bug/issue or report it to the
application/library provider some other way. This will let them know
that they need to change the downloads section and the documentation
to help their users avoid this issue.

## Here's how *not* to fix the problem

There's a some bad advice on how to fix this issue. Please do not
follow it.

There's some advice that says you can build your own version of
`glibc` and/or `libstdc++` and use them. I recommend not doing this.
Once you build your own version, you have to take ownership of
maintaining the build. That also means keeping up with all
`libc`/`libstdc++` security fixes and applying them and rebuilding
`libc`/`libstdc++`. That might be okay for a hobby project, but it's
not an appropriate solution for a production environment.

If you really, really know what you are doing and understand all the
maintenance, security and compatibility implications of it, there's
the last option: you can rebuild your own version of `glibc` or
`libstdc++`. There's [steps on how to build your own version of
`glibc` here](https://stackoverflow.com/a/50697155/3561275). And
there's [an even better way to run your just-built `glibc` that's
described here](https://askubuntu.com/a/319301).

But then again, if you fully understand all the ramification, you
wouldn't be reading this post to help understand and fix the error.
And you have probably spotted some ideas here that are not 100%
correct.

There's also some advice that it's okay to simply grab a version of
`glibc` from another version of your Linux distribution. That might
work. It might also completely break your installation. It might also
prevent any further updates to `glibc`/`libstdc++` via the
distribution's package manager.

## Conclusion

You should now know:

- What symbol versioning is
- How `libc` and `libstdc++` use symbol versioning
- What the `version GLIBC_X.Y not found` error messages mean
- What are some good ways to fix the errors:
  - Upgrading your Linux distribution
  - Using a compatible version of the library
- How *not* to fix this error!
