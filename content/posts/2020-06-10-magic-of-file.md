+++
title = "The magic of file"
author = "Omair Majid"
date = "2020-06-10"
categories = ["tools"]
tags = ["unix", "linux", "tools"]
+++

Ever wonder how `file(1)`[^1] works?

After reading this post, you should understand all about `file` and
it's underlying tool, `magic`.

## file

Using the `file` tool is quite simple. It's just `file file-name-1`.
You can call it with multiple arguments too. Here's a few examples of
running it on my system.

```shell
$ file document.pdf
document.pdf: PDF document, version 1.4
$ file image.jpg
image.jpg: JPEG image data, Exif standard: [TIFF image data, big-endian, direntries=7 ...orientation=upper-left, datetime=2019:10:30 21:44:30, width=1740], baseline, precision 8, 2017x961, components 3
$ file video.mp4
video.mp4: ISO Media, MP4 v2 [ISO 14496-14]
$ file notes.org
notes.org: UTF-8 Unicode text, with very long lines
$ file /dev/video0
/dev/video0: character special (81/0)
```

You can already see a few things:

1. It works on any file.

2. It tries to examine the contents of the file (not just the
   extensions) to figure out the file type.

3. It understands file formats in some detail. It can extract extra
   information from the file itself. You can see that it understands
   versions for mp4 and jpeg files.

4. It knows about special files like devices.

There's a few gotchas, though.

1. `file` may not do what you want in shell scripts.

   ```shell
   $ file no-such-file
   no-such-file: cannot open `no-such-file' (No such file or directory)
   $ echo $?
   0
   ```

   This version of `file` always seems to exit with a code of 0. Even
   when `file` can't figure it out. Even if the file doesn't exist.

2. For many formats that are not common on Unix/Linux, `file` is
   particularly fragile:

   ```shell
   $ file Vagrantfile
   Vagrantfile: HTML document, ASCII text
   $ file microsoft.netcore.app.2.1.19.nupkg
   microsoft.netcore.app.2.1.19.nupkg: Microsoft OOXML
   ```

   Yes, it really thinks a
   [`Vagrantfile`](https://www.vagrantup.com/docs/vagrantfile) is an
   HTML document and a [NuGet package
   file](https://www.nuget.org/packages/Microsoft.NETCore.App/2.1.19)
   is an Office document!

But how does `file` actually figure out the file type?

Like other classic Unix tools, `file` has excellent documentation.
[`man file`](https://man7.org/linux/man-pages/man1/file.1.html) points
out that `file` looks for things in this order.

1. It checks to see if a file is a special type of file, like devices.

2. It checks if the `magic(5)` database contains a "magic pattern"
   that can identify this file type.

3. It checks to see if it's a text-file. In this case, file will try
   and find out additional properties, such as language, encoding,
   line-length and the line terminator type (CR, LF, or CRLF).

`file` uses the result from the first check that works. If none of
these checks are successful, `file` simply reports the file type as
'data'.

The most interesting one of these is the `magic(5)` database option.
While the other checks are fairly static, you can examine the `magic`
database see how `file` works. You can even modify the database
manually to fix bugs[^2] in `file`!

## magic

The `magic` database is a plain text file. It is often located at
`/usr/share/magic`. You can view it in your favourite editor.

`/usr/share/magic` contains a series of test-and-output lines. A test
describes something to look for. If the test matches, the output is
printed.

Here's what a line might look like:

```text
0   string      Draw        RISC OS Draw file data
```

The first 3 columns are the test and the final column is the output.

This line specifies that at if the *string* at position *0* in the
file matches the constant string *Draw*, then show *RISC OS Draw file
data* as the file type.

To make things easier for the people maintaining the database, the
database supports nesting tests. That is, a test can say that it only
applies if the previous test matched.

Here's an example of a test and a nested test:

```text
0   belong      0xcafebabe
>4  belong      >30     compiled Java class data,
```

The first line is a test that can always be performed. The second line
contains a test that should only be performed if the first test is
successful, indicated by a ">" in the beginning of the line.

The first test here says: does the *big-endian long* at file position *0*
match the constant `0xcafebabe`. There's no output column, so it
doesn't do anything directly if it's successful.

However, if the test is successful, the nested test runs. The nested
test in this example checks if the *big-endian long* at position *4* in
the file is *greater than 30*. If that's true, print *compiled Java
class data*[^3].

`man 5 magic` contains extensive documentation that covers all the
syntax and options available if you want to learn about this in more
detail.

## a real life bug

Now that you know have a good understanding of `file` and `magic`,
lets see how you can use that to figure out a real life "bug".

As part of releasing .NET Core this week, one of the tools in our
release pipeline flagged an error saying the type of a particular file
had changed. The error looked something like this:

```diff
 file type changed for Microsoft.NETCore.App.Ref/3.1.0/data/PlatformManifest.txt:
-ASCII text
+Message Sequence Chart (chart)
```

The error is telling us that the file type changed from *ASCII text*
to *Message Sequence Chart (chart)*.

That error looks bogus. It's a text file. The extension is `.txt`.

The contents look like plain text too:

```text
$ head Microsoft.NETCore.App.Ref/3.1.0/data/PlatformManifest.txt
mscorlib.dll|Microsoft.NETCore.App.Ref|4.0.0.0|4.700.19.56404
System.IO.Compression.Native.a|Microsoft.NETCore.App.Ref||0.0.0.0
System.IO.Compression.Native.so|Microsoft.NETCore.App.Ref||0.0.0.0
```

So why is `file` saying this is a Message Sequence Chart? Let's see if
we can find an answer.

We know what algorithm `file` uses. So we will walk through it.

First, `file` will check if it's a special file. We can use `stat` to
find out what if that's true.

```shell
$ stat -c '%F' Microsoft.NETCore.App.Ref/3.1.0/data/PlatformManifest.txt
regular file
```

Here, `stat` confirms that this is regular file.

Next, `file` will use `magic` to guess the file type.

Does the `magic` database know about this file type at all?

```shell
$ grep 'Message Sequence Chart' /usr/share/magic
0       string          mscdocument     Message Sequence Chart (document)
0       string          msc             Message Sequence Chart (chart)
0       string          submsc          Message Sequence Chart (subchart)
```

Aha! It does.

For this set of tests, `magic` looks at the *string* at position *0*
and if it matches with *msc* (or *mscdocument*, or *submsc*), it
thinks this is a *Message Sequence Chart*.

If you recall, the first line of the text file was:

```shell
$ head Microsoft.NETCore.App.Ref/3.1.0/data/PlatformManifest.txt
mscorlib.dll|Microsoft.NETCore.App.Ref|4.0.0.0|4.700.19.56404
```

The first few bytes of the file incorrectly match with *msc*. `magic`
and `file` see the match and think this file is a *Message Sequence
Chart (chart)*.

This was clearly a false alarm from `file` (and our tooling). We
ignored it.

# closing thoughts

Hopefully, you now have a good idea of how `file` and `magic` work.
You also have a good starting point to use and debug these tools if


[^1]: The `thing(number)` convention is pretty common in Unix/Linux
    documentation. The `thing` part indicates the name of the concept.
    The `number` indicates the type of the thing as well as the
    section number of man pages where this thing is documented. For
    example, someone can be talking about `exec(1p)` and `exec(3)`. By
    `exec(1p)` they mean the one that is documented in section 1:
    Executable programs. So `exec(1p)` is the `exec` program. By
    `exec(3)` they mean the one that is documented in section 3:
    Library calls. So `exec(3)` is a library call. You can read the
    manual pages of a particular version by running `man 1p exec` or
    `man 3 exec`.

[^2]: If you do patch the database to fix a bug, please contribute the
    change back upstream.

[^3]: It turns out that Java class files and MACH executables use the
    same first sequence of bytes in the file (`0xcafebabe`). The next
    set of bytes can be used to guess whether this is Java class file
    or a MACH executable. Java class files have the class file version
    here, which is closer to 50. MACH executables use a much lower
    value. That's why the first test here for `0xcafebabe` doesn't
    print anything: at this point, `magic` doesn't have enough
    information to claim if this is Java or not.
