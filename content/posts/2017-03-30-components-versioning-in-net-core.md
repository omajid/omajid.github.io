+++
title = "Components & Versioning in .NET Core"
date = "Thu, 30 Mar 2017 22:14:31 +0000"
categories = [ "development", "dotnet" ]
aliases = [
    "/2017/03/30/components-versioning-in-net-core/",
]
+++
This post covers the versions and components in .NET Core 1.x.

## Components

.NET Core consists of multiple components that are each versioned
independently and can often be mixed and matched.

  - The **Shared Framework** contains the APIs and the Virtual Machine and other runtime services needed for running .NET Core applications.
    - The current .NET Core Virtual Machine is called **CoreCLR**. This executes the .NET bytecode by compiling it JIT and provides various runtime services including a garbage collector. The complete source code for CoreCLR is available at https://github.com/dotnet/coreclr.
    - The .NET Core standard APIs are implemented in **CoreFX**. This provides implementations of all your favourite APIs such as `System.Runtime`, `System.Theading` and so on. The source code for CoreFX is available at https://github.com/dotnet/corefx.
  - The **Host** is also sometimes called the _muxer_ or _driver_. This components represents the `dotnet` command and is responsible for deciding what happens next. The source for this is available at https://github.com/dotnet/core-setup.
  * The **SDK** consists of the various tools (`dotnet` subcommands) and their implementations that deal with building code. This includes handling the restoring of dependencies, compiling code, building binaries, producing packages and publishing standalone or framework dependent packages. The SDK itself consists of the _CLI_ , which handles command line operations (at https://github.com/dotnet/cli) and various subprojects that implement the various operations the CLI needs to do.

## Versions

Each of the components listed above are versioned separately. You can find out
the version of each of those components.

  * For the **SDK** , you can use the `--version` option to `dotnet` to see the version. For example:
    ```
    $ ~/dotnet-1.1.1/dotnet --version
    1.0.0-preview2-1-003176
    ```
  * For the **Host** you can run `dotnet` by itself without any arguments or options to see the version.
    ```
    $ ~/dotnet-1.1.1/dotnet
    Microsoft .NET Core Shared Framework Host
    Version : 1.1.0
    Build : 362e48a95c86b40cd1f2ef3d08741f7fed897956
    Usage: dotnet [common-options] [[options] path-to-application]
    ...
    ```
  * For the **Shared Framework** there no command currently to display the version(s). I use `ls /path/to/where/you/installed/dotnet/shared/Microsoft.NETCore.App` which relies on internal implementation details. For example:
    ```
    $ ls ~/dotnet-1.1.1/shared/Microsoft.NETCore.App/
    1.1.1
    ```

## Components in .NET Core Installations


Various official and unoffical packages, tarballs, zips and installers for
.NET Core (including those available on https://dot.net/core) provide .NET
Core in many variants. Two common ones are **.NET Core SDK** and **.NET Core
Runtimes**. Each .NET Core SDK or .NET Core Runtime distribution contains a
number (possibly 0) of hosts, sdk and shared framework components described
above.

  * **.NET Core Runtime** contains
    * 1 version of the _Host_
    * 1 version of the _Shared Framework_
  * **.NET Core SDK** contains
    * 1 or more versions of the _Shared Framework_ (varies depending on the version of the version of the .NET Core SDK)
    * 1 version of the _Host_
    * 1 version of the _SDK_

## Selecting Versions

It's possible to have multiple .NET Core SDKs and .NET Core Runtimes available
on disk. You can select the versions easily.

To select the version of the SDK to use, use `global.json`.

To select the version of the shared framework to use, use the `.csproj` file
(or `project.json` if you are still using that).


