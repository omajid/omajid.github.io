+++
title = "What glibc version do I care about?"
date = "2026-10-18"
draft = false
categories = [ "linux"  ]
tags = [ "linux", "glibc" ]
+++

Linux distributions include a C standard library, which allows programs written in C to use the standard library features (like `printf()` and `<limits.h>`), talk to the kernel without directly using syscalls, and so on.

Glibc is the most common implementation used on Linux, though there are others such as `musl` (used in Alpine), `llvm-libc` (by the LLVM project), `dietlibc` and `uclibc` (for embedded systems). Windows and BSDs have their own implementations of a C standard library, of couse.

If you are developing an application for Linux, you need to be careful with what glibc version you use. If you are shipping sources, you can rely on users/packagers/administrators to build your application against a specific glibc and then use the application. If you are shipping a binary for Linux, you need to be careful with what glibc you are linking against. The target platform may have a differen version of glibc. An application will run fine on a newer version of glibc; it will fail to run when an older verison of glibc is used.

In other words: glibc is often the first challenge when it comes to binary compatiblity on Linux.

If you need a binary to be widely compatible, make an explicit decision on what version of glibc it is built against.

Here's a compilation of some recent versions of glibc and what Linux distribution provide that version of glibc. Hopefully that will give you some good context on what a binary's compatiblity matrix might look like.

## glibc versions by linux distribution

| distribution name | glibc version |
| :-- | :-- |
| AlmaLinux 8  | 2.28 |
| AlmaLinux 9  | 2.34 |
| AlmaLinux 10  | 2.39 |
| CentOS Stream 9  |  2.34 |
| CentOS Stream 10  |  2.39 |
| Debian 9   | 2.24 |
| Debian 10  | 2.28 |
| Debian 11  | 2.31 |
| Debian 12  | 2.36 |
| Debian 13  | 2.41 |
| Fedora 30  | 2.29 |
| Fedora 40  |  2.39 |
| Fedora 44  |  2.43 |
| Fedora 45  | 2.44 |
| RHEL 8  | 2.28 |
| RHEL 9  | 2.34 |
| RHEL 10 |  2.39 |
| Rocky Linux 8 | 2.28 |
| Rocky Linux 9 |  2.34 |
| Rocky Linux 10  | 2.39 |
| Ubuntu 22.04  | 2.35 |
| Ubuntu 24.04  | 2.39 |
| Ubuntu 26.04  | 2.43 |
| Ubuntu 26.10  | 2.44 |

## glibc version and distro compatiblity

| glibc version | compatible minimum distributions |
| :-- | :-- |
| 2.24 | Debian 9 |
| 2.25 |  |
| 2.26 |  |
| 2.27 |  |
| 2.28 | AlmaLinux 8, Debian 10, RHEL 8, Rocky Linux 8 |
| 2.29 | Fedora 30 |
| 2.30 | |
| 2.31 | Debian 11 |
| 2.32 | |
| 2.33 | |
| 2.34 | AlmaLinux 9, CentOS Stream 9, RHEL 9, Rocky Linux 9 |
| 2.35 | Ubuntu 22.04 |
| 2.36 | Debian 12 |
| 2.37 | |
| 2.38 | |
| 2.39 | AlmaLinux 10, CentOS Stream 10, Fedora 40, RHEL 10, RockyLinux 10, Ubuntu 24.04 |
| 2.40 | |
| 2.41 | Debian 13 |
| 2.42 | |
| 2.43 | Fedora 44, Ubuntu 26.04 |
| 2.44 | Fedora 45, Ubuntu 26.10 |
| 2.45 | |


# How to find glibc versions


- If you know the path to the C sandard library, execute the library (yes!) directly:

  ```bash
  $ /usr/lib64/libc.so.6 | head -1
  GNU C Library (GNU libc) stable release version 2.43.
  ```

- You can also execute `ldd` to find out:

  ```bash
  $ ldd --version | head -1
  ldd (GNU libc) 2.43
  ```

- You can also ask your distribution's package manager:

  - Debian: `dpkg -s libc6 | grep "^Version"`
  - Fedora: `rpm -q --qf '%{VERSION}\n' glibc`
  - RHEL: `rpm -q --qf '%{VERSION}\n' glibc`

  Here's a full script that findes the version for each distribution:

  ```bash
  #!/bin/bash

  set -euo pipefail

  for alma in 8 9 10; do
      image=docker.io/library/almalinux:${alma}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
                /bin/bash -c 'rpm -q --qf "%{VERSION}\n" glibc')
      echo "AlmaLinux $alma  $glibc"
  done

  for centos in 9 10; do
      image=quay.io/centos/centos:stream${centos}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
              /bin/bash -c 'rpm -q --qf "%{VERSION}\n" glibc')
      echo "CentOS Stream $centos  $glibc"
  done

  for debian in 9 10 11 12 13 ; do
      image=docker.io/library/debian:${debian}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
              /bin/bash -c "dpkg -s libc6 | grep '^Version' | cut -d: -f2 | sed -E 's/-.*$//' ")
      echo "Debian $debian  $glibc"
  done


  for fedora in 30 40 44 45 46; do
      image=registry.fedoraproject.org/fedora:${fedora}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
                /bin/bash -c 'rpm -q --qf "%{VERSION}\n" glibc')
      echo "Fedora $fedora  $glibc"
  done

  for rhel in 8 9 10; do
      image=registry.access.redhat.com/ubi${rhel}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
              /bin/bash -c 'rpm -q --qf "%{VERSION}\n" glibc')
      echo "RHEL $rhel  $glibc"
  done

  for rocky in 8 9 10; do
      image=docker.io/rockylinux/rockylinux:${rocky}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
              /bin/bash -c 'rpm -q --qf "%{VERSION}\n" glibc')
      echo "Rocky Linux $rocky  $glibc"
  done

  for ubuntu in 22.04 24.04  26.04  26.10 ; do
      image=docker.io/library/ubuntu:${ubuntu}
      podman pull -q "${image}" > /dev/null
      glibc=$(podman run --pull=never -it "${image}" \
              /bin/bash -c "dpkg -s libc6 | grep '^Version' | cut -d: -f2 | sed -E 's/-.*$//' ")
      echo "Ubuntu $ubuntu  $glibc"
  done
  ```

---

This article was motivated by the [new regresion in `SQLitePCL.raw`, which breaks `Microsoft.Data.Sqlite` on RHEL 8](https://github.com/dotnet/efcore/issues/39148).

---
