+++
title = ".NET Core Symbols on Fedora"
date = "2020-08-05"
author = "Omair Majid"
categories = [ "dotnet" ]
tags = [ "dotnet", "fedora", "debugging" ]
+++

Have you ever tried to debug a .NET application and seen errors saying
debug information or debug symbols are not available?

What are debug symbols? Where are they used? When would you need them?
How do you get them? This post will try to resolve confusion by
calling out things you absolutely need to know about them.

## What are debug symbols?

Source code contains a lot of information that's not strictly part of
it's functionality. It contains human readable names, including names
of types, classes, methods and local variables. It contains lines of
code in an order that (hopefully!) makes it possible to understand
what is happening in order.

Generally, a good optimizing compiler will remove things that are not
strictly related to the functionality to produce efficient code. It
may remove local variables (but keep their effects). It may perform
some computations in advance at compile time to remove the amount of
work needed at runtime. It may re-order operations and computations to
produce more efficient code.

When you are debugging your code through a debugger you want to see
those local variables, their names and values. You want the additional
context like line numbers. Consider this: things like "step through
one line of code" become meaningless if the compiler has removed the
concept of a "line" entirely from the optimized binary.

Debug symbols try and produce the best of both worlds: you get the
optimized code but also keep much of the information in the original
source code to make it easier to debug your application.

If you are looking to debug a .NET Core application or [trace
performance](https://github.com/dotnet/runtime/blob/master/docs/project/linux-performance-tracing.md),
you will want to make use of debug symbols.

Debug symbols are also referred to as "debuginfo", "debug info" or
just "symbols", depending on the platform, language and tools. They
contain information used to make it possible to debug compiled and
optimized code. Some pieces of information that are present in the
debug symbols:

- Names of things that are not required to be visible for correct
  runtime behaviour, such as names of local variables.

- Line number information, including the line number in the original
  source code a particular computation happens in.

- Functions/methods that are executing that might have actually been
  in-lined into the method.

Each language, runtime or platform may have its own way of generating
and storing debug symbols. Each application, library and binary can
have its own debug symbols.

For example, if you are writing an application in C# that runs on top
of .NET Core running on top of Linux, multiple sets of debug symbols
are in play. Your application has its own debug symbols. And .NET Core
also has its own debug symbols. .NET Core runs on top of the C runtime
on Linux; the C runtime also has its own debug symbols.

For C# code, debug symbols are generated by the compiler (Roslyn) and
stored in `.pdb` ("Program Database") files. Tools like Visual Studio
Code can use these debug symbols to step through framework
implementation code.

For C and C++ code, the symbols vary by platform.

Binaries generated from C code on Windows also use `.pdb` files for
storing debug symbols.

Binaries on Linux, generated by compilers like `gcc` and `clang`, use
the DWARF format for symbols. These can be embedded in the binary or
kept in separate `.debug` files. Tools like `gdb` and `lldb` can load
these symbols (automatically or manually, depending on how you have
installed the SDK and symbols) and let you use them to step through
code and debug it.

Tools like `file` can tell you whether a binary has embedded debug
symbols or not:

```bash
$ file /usr/bin/file
/usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=e7df66a91efb28e483449a77221cb4242620541c, for GNU/Linux 3.2.0, stripped
```

The last word in the output, `stripped`, indicates that the debug
information has been remove from this binary.

It's important to note that **debug symbols are unique for each
binary**. Two binaries will not have the same debug symbols unless
they were compiled using the exact same sources by the exact same
compilers with the exact same set of dependencies.

## How to generate debug symbols for your own applications or libraries?

Most compilers, runtimes, and platforms support some way of generating
these debug symbols. Some even generate these symbols by default, but
most generate them only when explicitly asked to.

C/C++ compilers, such as `gcc` and `clang`, support using the `-g`
flag to produce debug symbols. This debug information is embedded in
the generated binaries. Tools like `objcopy` and `strip` can be used
to extract them into a separate file.

.NET Core generates debug symbols by default. You can turn it off
using the `DebugSymbols` and `DebugType` msbuild properties.

You can put that in your `.csproj` file:

```xml
<PropertyGroup>
  <DebugSymbols>false</DebugSymbols>
  <DebugType>None</DebugType>
</PropertyGroup>
```

Or set that through the command line:

```bash
$ dotnet publish -p:DebugSymbols=false -p:DebugType=None
```

However, unless turned off, you will see `.pdb` files being built and
published along with the rest of your application whenever you do
`dotnet build` or `dotnet publish`.

## What symbols are available for .NET Core itself?

.NET Core is itself an application too. Like other applications and
libraries, .NET Core also has its own debug symbols.

With these symbols, you can debug and/or profile the code in the
runtime and the framework libraries itself.

.NET Core has both managed and unmanaged (aka native) code. In fact,
it includes code compiled by (at least) two different compilers - the
C/C++ compiler that compiles the CLR and the low-level runtime as well
as the C# compiler that compiles the core framework libraries and the
rest of the framework written in C#.

Both these compilers generate different types of debug symbols. We
have to use and deal with managed and unmanaged debug symbols
separately.

## Where to get symbols for .NET Core?

The debug symbols are unique for each build of .NET Core. And they
also differ between each release of .NET Core.

The process for getting the symbols really depends on where you got
your .NET Core SDK and/or Runtime.

### .NET Core from Microsoft

If you have downloaded the .NET Core SDK and/or Runtime from
Microsoft, you can use the `dotnet symbol` tool to get symbol
packages:

```bash
$ dotnet tool install -g dotnet-symbol
$ dotnet symbol /usr/share/dotnet/dotnet
```

This `dotnet symbol` tool uses the Microsoft symbol server. The
Microsoft symbol server includes a copy of (hopefully) all the symbol
packages that Microsoft has ever built for .NET Core releases.

The tool simply asks the symbol server to download the symbol package
for a binary, based on the build id of the binary. If that symbol file
exists, `dotnet symbol` will download it.

You can also ask `dotnet symbol` to place the files in a given
location by using the `-o` flag:

```bash
$ dotnet symbol /usr/share/dotnet/dotnet -o my-symbol-directory
```

If you are worried about using it incorrectly, don't worry. The tool
will warn you and fail if you run it against any binary that the
Microsoft symbol server doesn't have symbols for:

```bash
$ dotnet symbol /usr/lib64/dotnet/dotnet
Downloading from http://msdl.microsoft.com/download/symbols/
ERROR: HttpSymbolStore: 404 Not Found 'http://msdl.microsoft.com/download/symbols/dotnet%2Felf-buildid-75e20435c061d0643096f93d91eb19701f7d6d13%2Fdotnet'
ERROR: HttpSymbolStore: 404 Not Found 'http://msdl.microsoft.com/download/symbols/_.debug%2Felf-buildid-sym-75e20435c061d0643096f93d91eb19701f7d6d13%2F_.debug'
```

### .NET Core packages from Fedora

The .NET Core packages that are included in Fedora and RHEL are built
from source. That means all the binaries included were built within
the Fedora build infrastructure.

Since these binaries are not identical to the .NET Core binaries built
by Microsoft, these debug symbols are different than the debug symbols
from Microsoft too. Microsoft doesn't have a copy of these debug
symbols from Fedora.

Fedora doesn't have its own symbol server. Fedora also doesn't want to
push to an external symbol server. You might think this would be a
problem.

Fortunately, Fedora already has a technique for shipping things: RPM
packages. It uses this for symbols too.

That's right: **symbols are available as ordinary RPM packages in Fedora!**

#### Managed Symbols

If you are using the Fedora packages for .NET Core (such as
`dotnet-sdk-3.1`), the managed symbols are installed as part of the
SDK/Runtime itself:

```bash
$ find /usr/lib64/dotnet/shared -name 'System.IO.FileSystem.[^A-Z]*'
/usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.pdb
/usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.dll
/usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.ni.{cfbfb1a5-d8bb-4fdd-835e-860da92311e2}.map
```

Lets go through the 3 files here:

1. The `.dll` file

   The `.dll` is the .NET assembly that contains the implementation of
   the `System.IO.FileSystem` namespace. (It's actually a crossgen'ed
   assembly, not plain .NET IL).

2. The `.pdb` file

   The `.pdb` file contains the debug symbols:

   ```bash
   $ file /usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.pdb
   /usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.pdb: Microsoft Roslyn C# debugging symbols version 1.0
   ```

3. The `.ni.map` file

   The `.ni.map` files contain information used by .NET performance
   tracing tools. It contains a map from the address in the binary to the
   names of the assembly methods that are being executed. This allows the
   performance tracing tools to identify the names of the methods from
   addresses.

---

Aside: If the pdb file size is significant enough that it impacts the
size of the SDK/runtime on disk for you, please let us know, we can
consider moving it to a separate package.

---

#### Unmanaged/Native Symbols

The unmanaged (or native) debug symbols are available through the
normal mechanisms on Fedora:

```bash
$ sudo dnf debuginfo-install 'dotnet*'
enabling fedora-modular-debuginfo repository
enabling updates-modular-debuginfo repository
enabling updates-debuginfo repository
enabling fedora-debuginfo repository
...
Dependencies resolved.
=================================================================================================
 Package                            Architecture     Version           Repository           Size
=================================================================================================
Installing:
 dotnet-apphost-pack-3.1-debuginfo  x86_64           3.1.6-1.fc32      updates-debuginfo   233 k
 dotnet-host-debuginfo              x86_64           3.1.6-1.fc32      updates-debuginfo   131 k
 dotnet-hostfxr-3.1-debuginfo       x86_64           3.1.6-1.fc32      updates-debuginfo   1.0 M
 dotnet-runtime-3.1-debuginfo       x86_64           3.1.6-1.fc32      updates-debuginfo    27 M
 dotnet-sdk-3.1-debuginfo           x86_64           3.1.106-1.fc32    updates-debuginfo   159 k
 dotnet3.1-debuginfo                x86_64           3.1.106-1.fc32    updates-debuginfo   686 k
 dotnet3.1-debugsource              x86_64           3.1.106-1.fc32    updates-debuginfo   7.6 M

Transaction Summary
=================================================================================================
Install  7 Packages

```

You can also explicitly install the native/unamanged symbols for any
specific (not just .NET COre) package by the full name-version with
the `dnf debuginfo-install` command on Fedora:

```bash
$ sudo dnf debuginfo-install dotnet-runtime-3.1 glibc python3
```

Once installed, you can use the native debugger, like `gdb` or `lldb`,
and they will automatically find, load and make use of the
just-installed unmanaged debug symbols on Fedora.

## Summary

You should now understand:

- What debug symbols are

- How they are specific for each language/runtime

- How you can generate them for .NET Core

- How you can get managed and unmanaged symbols for .NET Core on your system

If you ever need to profile or dig into the .NET Core source code for
debugging, you should now be able to understand the basics of what
role the debug symbols play in this.