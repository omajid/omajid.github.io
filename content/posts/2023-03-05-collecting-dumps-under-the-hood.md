+++
title = "Collecting dumps; under the hood"
date = "2023-03-05T01:32:23-05:00"
categories = [ "dotnet" ]
tags = [ "dotnet", "linux" ]
+++

Or how `dotnet-dump collect` works on Linux

If you are trying to diagnose the behaviour of a mis-behaving
application in production, one option is to use the
[`dotnet-dump`](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-dump)
tool to get a memory dump of the application so you can study it
offline. With a dump, you can get stack traces, look at all the
threads and even dig through the entire heap offline.

But how does `dotnet-dump` actually work?

This post will try and summarize what I found as I tried digging
through what `dotnet dump collect` does under the hood.

## The client

Let's start by looking at the first result of a google search for
"dotnet-dump": the [official documentation for `dotnet-dump`
command](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-dump).
That points to the [NuGet Package
page](https://www.nuget.org/packages/dotnet-dump) for `dotnet-dump`.
And the NuGet Package page has a link to the [source
repository](https://github.com/dotnet/diagnostics/).

Now we can poke around in https://github.com/dotnet/diagnostics [^1]
repository to find the source code for the `dotnet dump collect`
command.

There's a `src/Tools` directory which contains a `dotnet-dump`
directory. That seems like a likely candidate for the source code of
this tool. The
[Program.cs](https://github.com/dotnet/diagnostics/blob/main/src/Tools/dotnet-dump/Program.cs)
seems like a good place to start digging into the code.

There's a `CollectCommand` sub-command in that file that, which
matches with the `collect` sub-command name in the `dotnet dump` CLI
tool. The code looks roughly like this:

```C#
private static Command CollectCommand() =>
    new Command( name: "collect", description: "Capture dumps from a process")
    {
        // Handler
        CommandHandler.Create<...>(new Dumper().Collect),
        // Options
        ProcessIdOption(), OutputOption(), DiagnosticLoggingOption(), CrashReportOption(), TypeOption(), ProcessNameOption()
    };
```

There's a bit of boiler-plate involving how subcommands, arguments and
options are handled through `System.CommandLine`. The actual work is
done (using what `System.CommandLine` calls a `Handler`) by calling
`Dumper.Collect`.

Let's look into that. The
[`Dumper.Collect()`](https://github.com/dotnet/diagnostics/blob/main/src/Tools/dotnet-dump/Dumper.cs)
method looks something like this:

```C#
public partial class Dumper
{
    public int Collect(....)
    {
       // Lots of error handling
       if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
       {
           // ...
           Windows.CollectDump(...);
        }
        else
        {
            var client = new DiagnosticsClient(processId);
            // ...
            client.WriteDump(...) ;
        }
    }
}
```

That checks for the OS - Windows or Linux/macOS - and then calls
OS-specific code to handle each condition. For Linux, it calls into
the `DiagnosticsClient` class to create a dump.

The (relevant) core logic of the
[DiagnosticsClient](https://github.com/dotnet/diagnostics/blob/main/src/Microsoft.Diagnostics.NETCore.Client/DiagnosticsClient/DiagnosticsClient.cs)
class is this:

```C#
public sealed class DiagnosticsClient
{
    public DiagnosticsClient(int processId): this(new PidIpcEndPoint(processId))
    {
    }

    // ...
    public void WriteDump(...)
    {
       IpcMessage request = CreateWriteDumpMessage(...);
       IpcMessage response = IpcClient.SendMessage(...);
       // lots of error handling and fallback if IPC response
       // indicates failure
    }
}
```

This client is process-id based (this will come in handy later). To
write a dump, it creates a message and then sends it over some IPC
(Inter-Process Communication) mechanism via the `IpcClient`. A valid
response confirms that the dump was created.

What is this IPC mechanism? Who's listening on the other side?

## .NET diagnostics IPC

The interesting bits of
[`IpcClient`](https://github.com/dotnet/diagnostics/blob/main/src/Microsoft.Diagnostics.NETCore.Client/DiagnosticsIpc/IpcClient.cs)
look roughly like this:

```C#
internal class IpcClient
{
    public static IpcMessage SendMessage(IpcEndpoint endpoint, IpcMessage message)
    {
        IpcResponse response = SendMessageGetContunation(endpoint, message);
        return response.Message;
    }

    public static IpcResponse SendMessageGetContnuation(IpcEndpoint endpoint, IpcMessage message)
    {
        Stream stream = endpoint.Connect(...);
        Write(stream, message);
        IpcMessage response = Read(stream);
        return new IpcResponse(...);
    }

    public static void Write(Stream stream, IpcMessage message)
    {
       byte[] buffer = message.Serialize();
       stream.Write(buffer, ...);
    }
}
```
When we call `SendMessage`, it calls `SendMessageWithContinuation` to
the heavy work and then returns the response.
`SendMessageWithContinuation` connects to an endpoint, uses some form
of serialization to convert the request message to an array of bytes
and then writes those bytes into a stream.

Lets dig into these one by one

1. The `endpoint` is represented by the
   [`IpcEndpoint`](https://github.com/dotnet/diagnostics/blob/main/src/Microsoft.Diagnostics.NETCore.Client/DiagnosticsIpc/IpcTransport.cs)
   class. Remember how `DiagnosticsClient` had created a
   `PidIpcEndpoint` instance explcitly?

   The `PidIpcEndpoint` and related classes look roughly like this:

   ```C#
   internal abstract class IpcEndpoint
   {
       // ...
   }

   internal class PidIpcEndpoint : IpcEndpoint
   {
       public static stirng IpcRootPath { get; } = Path.GetTempPath();

       int _pid;
   
       public override Stream Connect(TimeSpan timeout)
       {
           string address = GetDefaultAddress();
           return IpcEndPointHelper.Connect(address, timeout)
       }

       private string GetDefaultAddress()
       {
           // ...
           TryGetDefaultAddress(_pid, out string transportName);
           return transportName;
       }

       private static bool TryGetDefaultAddress(int pid, out string defaultAddress)
       {
           defaultAddress = Directory.GetFiles(IpcRootPath, $"dotnet-diagnostic-{pid}-*-socket")
                                     .FirstOrDefualt();
           return defaultAddress;

       }
   }

   internal class IpcEndpointHelper
   {
       public static Stream Connect(...)
       {
           var socket = new IpcUnixDomainSocket()
           socket.Connect(new IpcUnixDomainSocketEndpoint(...));
           return new ExposedSocketNetworkStream(socket);
       }
   }
    ```
   The entrypoint to this code is supposed to be the
   `EndPoint.Connect` method. When `PidIpcEndpoint.Connect` is called,
   To summarize, it looks for a file matching a specific file name
   pattern in `/tmp`. After finding the file, the code opens the file
   as a unix domain socket and uses that for sending (and receiving)
   data.

2. The serialization mechanism

   ```C#
   internal class IpcMessage
   {
       public byte[] Serialize()
       {
           using (var writer = new BinaryWriter(...))
           {
               writer.Write(...);
               writer.Flush();
               serializedData = stream.ToArray();
               return serializedData;
           }
       }
   }
   ```

   This uses simple `BinaryWriter`-based serialization.

Okay, so now we know that we are using `BinaryWriter`-based
serialization to send a message to a socket. Is this something ad-hoc
or part of an intentionally designed feature in .NET?

## .NET diagnostic sockets

It turns out that this socket is an intentional part of the of the
.NET runtime.

Whenever a .NET process starts, it creates a socket (file) at
`/tmp/dotnet-diagnostics-${pid}-${random}-socket`:

```sh
$ ps aux | grep 1688[7]
omajid     16887  0.0  0.3 273609920 103020 pts/6 Sl+ 16:42   0:00 /home/omajid/local/dotnet/microsoft/7.0.101/dotnet --roll-forward major bin/Debug/net6.0/Pause.dll
$ ls -al /tmp/dotnet-diagnostic-16887*socket
srw-------. 1 omajid omajid 0 Dec 22 16:42 /tmp/dotnet-diagnostic-16887-1636599-socket
$ stat /tmp/dotnet-diagnostic-16887-1636599-socket
  File: /tmp/dotnet-diagnostic-16887-1636599-socket
  Size: 0               Blocks: 0          IO Block: 4096   socket
Device: 0,37    Inode: 259         Links: 1
Access: (0600/srw-------)  Uid: ( 1000/  omajid)   Gid: ( 1000/  omajid)
Context: unconfined_u:object_r:user_tmp_t:s0
Access: 2022-12-22 16:42:42.097080354 -0500
Modify: 2022-12-22 16:42:42.097080354 -0500
Change: 2022-12-22 16:42:42.097080354 -0500
 Birth: 2022-12-22 16:42:42.097080354 -0500
```

A custom protocol - based on `BinaryWriter` serialization - is used to
send messages across this. This is what the all the code that we have
seen so far has been doing.

The full IPC protocol is documented in
[`ipc-protocol.md`](https://github.com/dotnet/diagnostics/blob/main/documentation/design-docs/ipc-protocol.md).

We still have a remaining question: who is listening on the other
side and how do they handle these messages? The IPC protocol gives a
great hint:

> .. IPC Protocol [is] used for communicating
> with the dotnet core runtime's Diagnostics Server

What is this?

## The .NET Runtime

Following the hint, lets try and dig through the dotnet/runtime code.
If you want to follow along, you can find the source code for code for
the .NET runtime at https://github.com/dotnet/runtime/.

We can start by searching the CoreCLR VM in the runtime for anything
related to diagnostics:

```
$ find src/coreclr/vm -iname '*diagnostic*'
src/coreclr/vm/diagnosticserveradapter.h
```

That seems like a great starting point! It seems to defer everything
to `ds-server.c`.

The initialization code of the diagnostics server is defined in
[`ds_server_init`](https://github.com/dotnet/runtime/blob/615de00422f4f8d80e0009da1a117cc06dbb57e0/src/native/eventpipe/ds-server.c#L189).
It looks, roughly like this:

```c++
bool ds_server_init(void)
{
    // lots of initialization
    ep_rt_thread_create(server_threads, ...);
}

void server_thread()
{
    // ...
    while (!server_shutting_down)
    {
        DiagnosticsIpcMessage message;
        ds_ipc_message_init(&message)
        ds_ipc_message_inititalize_stream(&message, stream)
        switch (ds_ipc_header_get_command(...))
        {
            case DS_SERVER_COMMANDSET_DUMP:
			    ds_dump_protocol_helper_handle_ipc_message (&message, stream);
                break;
        }
    }
}
```

This thread runs forever, waiting for any diagnostics commands.


When a diagnostics command is received, this calls
`ds_dump_protocol_helper_handle_ipc_message` to handle the message and
write the dump to an on-disk location:
https://github.com/dotnet/runtime/blob/e467a5f65a4fb6b0b703a5c1c22c519114e99845/src/native/eventpipe/ds-dump-protocol.c#L243

That eventually leads to
[`PAL_GenerateCoreDump`](https://github.com/dotnet/runtime/blob/e07f4527bdedff6278accf9db8a8c7f9f2a48beb/src/coreclr/pal/src/thread/process.cpp#L2337).
That looks roughly like this:

```c++
PAL_GenerateCoreDump(
    ...)
    {
        // ...
        std::vector<const char*> argvCreateDump
        char* program = nullptr;
        char* pidarg = nullptr;
        PROCBuildCreateDumpCommandLine(argvCreateDump, &program, &pidarg);
        PROCCreateCrashDump(argvCreateDump);
    }

PROCBuildCreateDumpCommandLine(
    std::vector<const char*>& argv,
    ...)
    {
        // ...
        const char* DumpGeneratorName = "createdump";
        argv.push_back(program);
        argv.push_back(pidarg);
        // ...
    }
```

Hang on a second, this just runs the `createdump` command! This
command is included with the .NET runtime, on your disk:

```bash
$ find /usr/lib64/dotnet/ -name createdump
/usr/lib64/dotnet/shared/Microsoft.NETCore.App/7.0.2/createdump
/usr/lib64/dotnet/shared/Microsoft.NETCore.App/6.0.13/createdump
```

`createdump` is also included with self-contained applications.
There's some discussion on how it should be removed
[here](https://github.com/dotnet/sdk/issues/27336).

# What does `createdump` do?

We can start by searching the dotnet/runtime repository for any file
that might look like it's relevant to the createdump command.
Searching for such files leads me to a promisingly named
createdump/main.cpp file:
https://github.com/dotnet/runtime/blob/f1bdd5a6182f43f3928b389b03f7bc26f826c8bc/src/coreclr/debug/createdump/main.cpp

Let's start with the `main` method. It looks like this:

```c
int __cdecl main(const int argc, const char* argv[])
{
    // lots of argument parsing
    if (CreateDump(dumpPathtTemplate, pid, ...))
    {
       // success
    }
    // cleanup and exit
}
```

`CreateDump` is defined in createdumpunix.cpp for Linux and macOS
https://github.com/dotnet/runtime/blob/f1bdd5a6182f43f3928b389b03f7bc26f826c8bc/src/coreclr/debug/createdump/createdumpunix.cpp#L14

There's a ton of code to dig through, and a lot of it goes down into
Linux-specific detail. I might do a detailed walk-through in another
post. But here are the important points:

1. `CreateDump` calls `CrashInfo::EnumerateAndSuspendThreads`, which
  uses `ptrace(2)` to suspend all threads in the .NET application

2. `CreateDump` calls `CrashInfo::GatherCrashInfo` to collect data:

   1. Get information from `/proc/$PID/auxv` (the auxillary vector
      data).

   2. Get information from `/proc/pid/maps` about the memory regions

   3. Use the DAC (Data Access Component) of the runtime to find the
      managed modules

   4. Unwind all the threads

3. Use the DAC again to enumerate the managed memory regions.

4. Write the dump out as an ELF file.

On a side note, the last point is particularly interesting.
`createdump` writes out a regular ELF core file. This is a standard
core file, similar to those produced by other tools like `gcore`. It's
in a format that's readable by both `dotnet dump analyze` but also
native debugging tools like `lldb` and `gdb`. The corefile can be used
to debugged applications using `gdb`/`lldb`, but they will need the
unmanaged (or native) debug symbols. That's not true for `dotnet dump
analyze` which - surprise - again makes use of the DAC to figure out
the managed state of the application.

When all that is done, we finally get the core file that we were
looking for!

# Summary

That was a lot to chew through. So let's do a quick recap of what
happens when we use `dotnet dump collect.

- The `dotnet dump` tool parses the user's command and figures out
  that the user wants to trigger a particular type of dump.

- `dotnet dump` creates a specially crafted message that it sends to
  the target .NET application over the .NET diagnostics socket.

- The .NET runtime receives the message over the socket and parses it.

- The runtime then runs `createdump` as a separate process, pointing
  `createdump` to the .NET application itself.

- `createdump` pauses the target .NET application and collects
  everything needed from the application by walking through the
  managed memory (with the help of the DAC) and the unmanaged memory.

- `createdump` writes out the dump to disk.

At the end of this, we finally have a file on disk that contains the
application's dump

There are some interesting consequences that come up because of this
approach:

0. .NET runtimes provides a mechanism for other applications to
   request information from them. If this mechanism is turned off (eg,
   via
   [`DOTNET_EnableDiagnostics`](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-environment-variables#dotnet_enablediagnostics)),
   then tools like `dotnet-dump` become useless.

1. Thanks to a single protocol, it's possible for `dotnet dump
   collect` to work against any number of different .NET runtimes and
   versions. And All runtime-specific detail is handled by the
   runtime's built-in `createdump` command.

2. Some folks have tried removing the `createdump` binary from their
   published applications to save on size. Removing `createdump` from
   those applications means tools like `dotnet-dump` aren't fully
   funtional against those applications. Their applications can become
   harder to diagnose.

3. If you really need to, you can take advantage of the diagnostics
   protocol and write your own custom tools to talk to the .NET
   runtime.


[^1]: I have linked to the classes/files on GitHub, but it might
      easier to clone the repo and look through it using your
      favourite tools.
