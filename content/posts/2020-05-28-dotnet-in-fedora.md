+++
title = ".NET Core is now available in Fedora"
author = "Omair Majid"
categories = [ "development" ]
tags = [ "fedora", "dotnet" ]
+++

One exciting feature in the recent release of Fedora 32 is the
inclusion of .NET Core in the default repositories. This makes Fedora
32 the first community Linux distribution with .NET Core available out
of the box!

In this post, lets take a quick look at using .NET Core on Fedora 32.
We will cover installing .NET Core packages and building a container
image. All using software only from Fedora!

.NET Core is being maintained by the Fedora DotNet SIG:
https://fedoraproject.org/wiki/SIGs/DotNet

## Installing .NET Core packages on Fedora 32

With Fedora 32, .NET Core 3.1 is included in the default repositories.
In the future, additional versions will be added as they are released.
And older versions will be removed as they go End-of-Life.

You can pick and choose which components of .NET Core (SDK, Runtime)
you need and install just those. Installing a component will install
all of its dependencies. For example, installing a .NET Core SDK will
also install the corresponding .NET Core Runtime as well as any other
additional SDK dependencies.

You can install a the .NET Core SDK by using `dnf`:

```shell
dnf install dotnet-sdk-3.1
```

If you are not interested in developing .NET Core applications, rather
just running them, you can skip the SDK and only install the
.NET Core Runtime. For example:

```shell
dnf install dotnet-runtime-3.1
```

You also can install the ASP.NET Core Runtime, which lets you run
framework-dependent ASP.NET Core applications:

```shell
dnf install aspnetcore-runtime-3.1
```

Future versions of .NET Core packages should follow the same
convention:

- `dotnet-sdk-X.Y`
- `dotnet-runtime-X.Y`
- `aspnetcore-runtime-X.Y`

(Aside: Maybe the last one will change when ASP.NET Core is renamed to
ASP.NET?)

## Running .NET Core

Once you have installed .NET Core on Fedora 32, you can simply start
using the `dotnet` command. To make sure .NET Core is installed, try:

```shell
dotnet --info
```

That should show more information about .NET Core, including the specific components that are installed:

```shell
.NET Core SDK (reflecting any global.json):
 Version:   3.1.103
 Commit:    6f74c4a1dd

Runtime Environment:
 OS Name:     fedora
 OS Version:  32
 OS Platform: Linux
 RID:         fedora.32-x64
 Base Path:   /usr/lib64/dotnet/sdk/3.1.103/

Host (useful for support):
  Version: 3.1.3
  Commit:  4a9f85e9f8

.NET Core SDKs installed:
  3.1.103 [/usr/lib64/dotnet/sdk]

.NET Core runtimes installed:
  Microsoft.AspNetCore.App 3.1.3 [/usr/lib64/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 3.1.3 [/usr/lib64/dotnet/shared/Microsoft.NETCore.App]

To install additional .NET Core runtimes or SDKs:
  https://aka.ms/dotnet-download
```

We can now use .NET Core SDK to create, build, publish, and run a simple Hello World application:

```shell
$ mkdir HelloWorld
$ cd HelloWorld/
$ dotnet new console
The template "Console Application" was created successfully.

Processing post-creation actions...
Running 'dotnet restore' on /HelloWorld/HelloWorld.csproj...
  Restore completed in 51.55 ms for /HelloWorld/HelloWorld.csproj.

Restore succeeded.

$ dotnet publish --configuration Release --runtime fedora.32-x64 --self-contained false
Microsoft (R) Build Engine version 16.4.0+e901037fe for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 64.74 ms for /HelloWorld/HelloWorld.csproj.
  HelloWorld -> /HelloWorld/bin/Release/netcoreapp3.1/fedora.32-x64/HelloWorld.dll
  HelloWorld -> /HelloWorld/bin/Release/netcoreapp3.1/fedora.32-x64/publish/

$ dotnet bin/Release/netcoreapp3.1/fedora.32-x64/publish/HelloWorld.dll
Hello World!

```

See the .NET Core documentation for more information, including
references, samples, and tutorials.

If you run into any issues, please file bugs in the Fedora bugzilla
against the `dotnet3.1` package.

## Using .NET Core in Fedora-based container images

You can use these container images to develop and deploy your .NET
Core applications in containerized environments, such as OpenShift and
Kubernetes.

### Running .NET Core containers

You can use the Fedora-based containers in your container pipelines.
You can use it for deployment to cloud environments.

As an example, let’s create, build, and run a Hello World-style
application in a container. Create a `Dockerfile` that contains the
following:

```dockerfile
FROM fedora:32

RUN dnf install dotnet-sdk-3.1 -y && \
    dotnet --info && \
    dotnet new console -o HelloWorld && \
    cd HelloWorld && \
    dotnet publish --configuration Release

ENTRYPOINT dotnet HelloWorld/bin/Release/netcoreapp3.1/publish/HelloWorld.dll
```

You can build and run this using `podman` or `docker` commands:

```shell
$ podman build -t hello .
TEP 1: FROM fedora:32
STEP 2: RUN dnf install dotnet-sdk-3.1 -y &&     dotnet --info &&     dotnet new console -o HelloWorld &&     cd Hell$
World &&     dotnet publish --configuration Release
Fedora Modular 32 - x86_64                                                            338 kB/s | 4.9 MB     00:14
Fedora Modular 32 - x86_64 - Updates                                                  313 kB/s | 1.3 MB     00:04
Fedora Modular 32 - x86_64 - Test Updates                                             157 kB/s | 196 kB     00:01
Fedora 32 - x86_64 - Test Updates                                                     367 kB/s |  19 MB     00:53
Fedora 32 - x86_64 - Updates                                                          745 kB/s | 5.8 MB     00:07
...
...
...
Microsoft (R) Build Engine version 16.4.0+e901037fe for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 14.63 ms for /HelloWorld/HelloWorld.csproj.
  HelloWorld -> /HelloWorld/bin/Release/netcoreapp3.1/HelloWorld.dll
  HelloWorld -> /HelloWorld/bin/Release/netcoreapp3.1/publish/
--> 9d475fd86ba
STEP 3: ENTRYPOINT dotnet HelloWorld/bin/Release/netcoreapp3.1/publish/HelloWorld.dll
STEP 4: COMMIT hello
--> ddafbd4fc68
ddafbd4fc68b0d81c17da7c2b3bcf49ef2a9605d1181fd41f4811d3ff0ac4ae7

$ podman run -it hello
Hello World!
```

Hello World, from the exciting land of containers!

