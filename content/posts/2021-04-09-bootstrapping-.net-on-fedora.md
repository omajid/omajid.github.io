+++
title = "Build .NET and avoid prebuilts: Bootstrapping .NET in Fedora"
date = "2021-04-09"
author = "Omair Majid"
categories = [ "dotnet" ]
tags = [ "dotnet", "fedora" ]
+++

# Why Bootstrap?

Compiling code is supposed to be straightforward: you run a compiler
over the code and the compiler gives you back an executable program.

But what do you do if there's no compiler?

That's the dilemma .NET runs into in Fedora.

Every release of .NET (Core) needs a recent version of a .NET (Core)
SDK that can be used to build it. But that's exactly what's missing
and what we are trying to build.

The general solution to this chicken-and-egg problem is called
[bootstrapping](https://en.wikipedia.org/wiki/Bootstrapping_(compilers)).
Generally speaking, you somehow produce a runnable compiler (hacks are
allowed) that understands your programming language, and then use that
to build the real thing.

In Fedora, we use a slight variant of this.

# Process

The rough process looks like this:

1. Build the bootstrap tarball, for each architecture:

   ```bash
   ./build-dotnet-tarball --bootstrap v5.0.104-SDK
   ```

   That will produce a `dotnet-v5.0.104-SDK-x64-bootstrap.tar.gz`.

   You can repeat this command for multiple architectures (such as
   `aarch64`) if you want.

2. Configure and conditionalize the RPM spec file that you are working
   with for building in bootstrap mode. [Fedora suggests doing it like
   this](https://docs.fedoraproject.org/en-US/packaging-guidelines/#bootstrapping):

   ```shell
   # This (badly named) option says to build in "bootstrap" mode by default
   %bcond_without bootstrap

   %if %{with bootstrap}
   # special hacks for bootstrapping
   %endif

   %if %{without bootstrap}
   BuildRequires: dotnet-sdk-5.0
   BuildRequires: dotnet5.0-source-build-reference-packages
   %endif

   %if %{without bootstrap}
   # remove prebuilts
   find -type f -iname '*.dll' -delete
   %endif

   ```

3. Upload sources and commit spec file. Just follow the normal build
   process for any RPM build. *But don't build it yet*.

   ```shell
   fedpkg new-sources dotnet-v5.0.104-SDK-x64-bootstrap.tar.gz dotnet-v5.0.104-SDK-arm64-bootstrap.tar.gz
   git add dotnet5.0.spec
   git commit -m "Bootstrap .NET 5"
   git push
   ```

4. [Create a
   side-tag](https://fedoraproject.org/wiki/Package_update_HOWTO#Creating_a_side-tag).
   Builds done in a side-tag can not become part of the main release
   accidentally. This helps avoid accidentally shipping prebuilts,
   especially in rawhide.

   ```shell
   fedpkg request-side-tag
   ```

   If you are building for an RPM-based distribution without support
   for side-tags, you can skip this step and just do a normal build in
   the next step.

5. Build the RPM with bootstrap binaries in the side-tag:

   ```shell
   fedpkg build --target=f35-build-side-foobar
   ```

6. Build the
   [source-build-references-package](https://github.com/dotnet/source-build-reference-packages/).
   This is a [regular package with a normal
   spec](https://src.fedoraproject.org/rpms/dotnet5.0-build-reference-packages)
   file that can `BuildRequire` the just-built `dotnet-sdk-5.0`
   package. Built it in your side-tag, though:

   ```shell
   fedpkg build --target=f35-build-side-foobar
   ```

7. Once the build works, we can proceed with disabling bootstrapping.
   Produce non-bootstrap source-tarball for the same version:

   ```shell
   ./build-dotnet-tarball v5.0.104-SDK
   ```

   Leaving out `--bootstrap` will produce a `dotnet-v5.0.104-SDK.tar.gz`.

8. Then disable bootstrapping in the spec file. If you got step 2
   right, it should be as easy as this change to your spec file:

   ```diff
   -%bcond_without bootstrap
   +%bcond_with bootstrap
   ```

   The strangely named `%bcond_with bootstrap` means "build *without*
   bootstrap by default".

   [Here's an example of this in
   Fedora](https://src.fedoraproject.org/rpms/dotnet5.0/c/2e4240bf831b134d40326b808eee0b02eb7a4d11?branch=rawhide).

9. Upload the new source tarball and commit+push the spec file
   changes. Then build it again in the side-tag:

   ```shell
   fedpkg new-sources dotnet-v5.0.104-SDK.tar.gz
   git add dotnet5.0.spec
   git commit -m "Disable bootstrap"
   git push
   fedpkg build --target=f35-build-side-foobar
   ```

   If it fails, try and fix that. Maybe something was broken in the
   initial build? If so, you might have to revert step 8 and rebuild
   the bootstrap build.

10. If the above steps worked, you can take the final non-bootrap
    build and [file an update - use the "Use Side Tag"
    option](https://bodhi.fedoraproject.org/updates/new) - to ship that
    package out to users!

Congrats!

# Benefits

Aside from solving the chicken-and-egg problem and following the
no-prebuilts-binaries-allowed rule of Fedora, this also solves a few
other problems.

The original source-tarball for a .NET SDK release is architecture
specific: it contains compiler binaries specific to an architecture.
If we wanted to build .NET on 3 architectures, we would need to
produce every source-tarball 3 times!

Building per-architecture requires additional machines (who has 3
architectures handy?). It requires additional time: many
architectures are slower than common x86_64 developer machines. It
also requires additional upload bandwidth/time: 3 times 2GB archives
add up to a lot of delay uploading tarballs.

By switching to a single architecture neutral tarball without any
prebuilts, we cut down source-tarball build and upload time
by a few orders of magnitude.

# Try it out

If you are packaging .NET for a RPM-based distribution, try out
bootstrapping it! Let me know if it works or not. You can also [report
issues in source-build](https://github.com/dotnet/source-build).

---
