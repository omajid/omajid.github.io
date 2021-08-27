+++
title = "What is nuget restore doing?"
date = "Fri, 29 May 2020 18:34:41 +0000"
categories = [ "development" ]
tags = [ "dotnet", "msbuild", "nuget"]
aliases = [
    "/posts/what-nuget-sources/",
]
+++

Ever wonder what `nuget` or `dotnet restore` is doing? What feeds it
using? Or what `nuget.config` it is using to find feeds?

Turns out you can find out what nuget-related information `dotnet
restore` by looking at the logs.

Generally, `dotnet restore` is succinct. Restoring a `HelloWorld`
project gives us little information about what's going on:

```shell
$ dotnet new console --no-restore
The template "Console Application" was created successfully.
$ dotnet restore
  Restore completed in 72.1 ms for /home/omajid/cliche/dotnet/HelloWorld/HelloWorld.csproj.
```

If we add a `nuget.config` file, we still see little information. Not
even enough to know if it's even being used:

```shell
$ rm -rf *
$ dotnet new console --no-restore
The template "Console Application" was created successfully.
$ dotnet new nugetconfig
The template "NuGet Config" was created successfully.
$ ls
HelloWorld.csproj  nuget.config  Program.cs
$ dotnet restore
  Restore completed in 52.87 ms for /home/omajid/cliche/dotnet/HelloWorld/HelloWorld.csproj.
```

And it certainly doesn't give us a hint about any other `nuget.config`
files are being used.

But we can find out more from `dotnet restore` by increasing the
verbosity to `normal`:

```shell
$ rm -rf *
$ dotnet new console --no-restore
The template "Console Application" was created successfully.
$ dotnet new nugetconfig
The template "NuGet Config" was created successfully.
$ dotnet restore --verbosity:normal
Build started 5/29/2020 11:14:01 PM.
     1>Project "/home/omajid/cliche/dotnet/HelloWorld/HelloWorld.csproj" on node 1 (Restore target(s)).
     1>Restore:
         Restoring packages for /home/omajid/cliche/dotnet/HelloWorld/HelloWorld.csproj...
         Committing restore...
         Generating MSBuild file /home/omajid/cliche/dotnet/HelloWorld/obj/HelloWorld.csproj.nuget.g.props.
         Generating MSBuild file /home/omajid/cliche/dotnet/HelloWorld/obj/HelloWorld.csproj.nuget.g.targets.
         Writing assets file to disk. Path: /home/omajid/cliche/dotnet/HelloWorld/obj/project.assets.json
         Restore completed in 54.6 ms for /home/omajid/cliche/dotnet/HelloWorld/HelloWorld.csproj.

         NuGet Config files used:
             /home/omajid/cliche/dotnet/HelloWorld/nuget.config
             /home/omajid/.nuget/NuGet/NuGet.Config

         Feeds used:
             https://api.nuget.org/v3/index.json
     1>Done Building Project "/home/omajid/cliche/dotnet/HelloWorld/HelloWorld.csproj" (Restore target(s)).

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.43
```

Now we can see a list of all the `nuget.config` files being used.
Turns out there is one in my home directory at
`~/.nuget/NuGet/NuGet.config` that I probably would have missed even
if I had dug around in the project directory.

If you are wondering about the particular output format, this is just
the normal log output from `msbuild`. That's why we see a `Task`
called `Restore` running.

There are a couple of possible configurations for verbosity. `q` (or
`quiet`) is the default. `n` (or `normal`) can be handy. `diagnostic`
or `detailed` can show a *lot* of information that can be a bit hard
to parse by hand.

You can even make the invocation smaller: `dotnet restore -v:n` sets
verbosity (via `-v`) to normal (via `n`).

Hopefully, you now have a new tool to debug/traces any issues you
might be hitting during `dotnet restore`!
