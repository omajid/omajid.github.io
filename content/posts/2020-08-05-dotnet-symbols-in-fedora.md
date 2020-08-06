+++
title = ".NET Core Symbols on Fedora"
date = "2020-08-06T19:33:29-04:00"
author = "Omair Majid"
categories = [ "dotnet" ]
tags = [ "dotnet", "fedora", "debugging" ]
+++

Have you ever tried to debug an application and seen errors saying
debug information or debug symbols are not available? If you are
looking to debug a .NET Core application or [trace
performance](https://github.com/dotnet/runtime/blob/master/docs/project/linux-performance-tracing.md),
you will want to make use debug symbols.

## What are debug symbols?

Source code contains a lot of information that's not strictly part of
it's functionality. It contains human readable names, including names
of types, classes, methods and local variables. It contains lines of
code in an order that (hopefully!) makes it possible to understand
what is happening in order.

Generally, a good optimizing compiler will remove many of these things
that are not strictly related to the functionality to produce
efficient code. It may remove local variables (but keep their
effects). It may perform computations in advance to remove the amount
of work needed at runtime. It may re-order operations to produce more
efficient code.

When you are debugging your code, though, you want to see those local
variables, their names and values. Debug symbols try and produce the
best of both worlds: you get the optimized code but also keep much of
the information in the original source code to make it easier to debug
your application.

Debug symbols are also referred to as "debuginfo", "debug info" or
just "symbols". They contain information used to make it possible to
debug compiled and optimized code. Some pieces of information that are
available in through symbols:

- Names of many things that are not public API, such as names of local
  variables.

- Line information, like a mapping from source code lines to the
  information in binary. This makes it possible for

- Names/values of local variables.

Each language/runtime has its own type of debug system and way of
generating debug symbols.

So we have to deal with managed and unmanaged debug symbols
separately.

For .NET code, debug symbols generated and stored in `.pdb` ("Program
Database") files. Tools like Visual Studio Code can use these debug
symbols to step through framework implementation code.

For C code, the symbols vary by platform.

Binaries generated from C code on Windows also use `.pdb` files for
storing debug symbols.

Binaries on Linux, using the common ELF format, use DWARF format for
symbols. These can be embedded in the binary or kept in separate
`.debug` files. Tools like `gdb` and `lldb` can load these symbols
(automatically or manually, depending on how you have installed the
SDK and symbols) and let you use them to step through code and debug
it.

## How to (not) generate managed debug symbols?

Most compilers/platforms support some way of generating these debug
symbols. Some platforms even generate these symbols by default, but
most generate them only when explicitly asked to.

C/C++ compilers, such as `gcc` and `clang`, support using the `-g`
flag to produce this debug symbol information. This debug information
is embedded in the generated binaries. Tools like `objcopy` and
`strip` can be used to extract them into a separate file.

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

## Where to get symbols for .NET Core?

This mainly depends on where you got your .NET Core build.

### .NET Core packages from Microsoft

If you have downloaded the .NET Core SDK or Runtime from Microsoft,
you can use the `dotnet symbol` tool to get symbol packages:

```bash
$ dotnet tool install -g dotnet-symbol
$ dotnet symbol /usr/share/dotnet/dotnet
```

You can also ask `dotnet symbol` to place the files in a given
location by using the `-o` flag:

```bash
$ dotnet symbol /usr/share/dotnet/dotnet -o my-symbol-directory
```

If you are worried about using it incorrectly, don't worry. The tool
will warn you and fail if you run it against any binary that it
doesn't have symbols for:

```bash
$ dotnet symbol /usr/lib64/dotnet/dotnet
Downloading from http://msdl.microsoft.com/download/symbols/
ERROR: HttpSymbolStore: 404 Not Found 'http://msdl.microsoft.com/download/symbols/dotnet%2Felf-buildid-75e20435c061d0643096f93d91eb19701f7d6d13%2Fdotnet'
ERROR: HttpSymbolStore: 404 Not Found 'http://msdl.microsoft.com/download/symbols/_.debug%2Felf-buildid-sym-75e20435c061d0643096f93d91eb19701f7d6d13%2F_.debug'
```

### .NET Core packages from Fedora

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

The `.dll` is the actual .NET assembly that contains the
`System.IO.FileSystem` namespace. (It's a crossgen'ed assembly, not
plain .NET IL).

The `.pdb` is the file that contains the debugging symbols:

```bash
$ file /usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.pdb
/usr/lib64/dotnet/shared/Microsoft.NETCore.App/3.1.6/System.IO.FileSystem.pdb: Microsoft Roslyn C# debugging symbols version 1.0
```

The `.ni....map` files contain information used by .NET performance
tracing tools. It contains a map from the address in the binary to the
names of the assembly methods that are being executed. This allows the
performance tracing tools to identify the names of the methods from
addresses.

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

## Summary

You should now understand:

- What debug symbols are

- How they are specific for each language/runtime

- How you can generate them for .NET Core

- How you can get managed and unmanaged symbols for .NET Core on your system

If you ever need to profile or dig into the .NET Core source code for
debugging, you should now be able to understand the basics of what is
going on.
