+++
title = "Contributing Patches to OpenJDK"
date = "Fri, 13 Sep 2013 23:43:03 +0000"
aliases = [
    "/2013/09/13/contributing-patches-to-openjdk/",
]
+++
Someone asked me earlier today about how to contribute patches to OpenJDK.
OpenJDK is probably not the easiest upstream to contribute patches to - their
patch approval system is a little different from most other projects. I have
tried to summarize the basic steps here. Let me know in comments if anything
is not clear.

The OpenJDK [Developer's Guide](http://openjdk.java.net/guide/ "The OpenJDK Developer's Guide") covers most of this, but some of it is in too much detail and some of it is outdated. The process I describe here is what I have seen others use and what I have been using myself.

The overall process for submitting patches to OpenJDK is:

  1. Identify what _group_ or _project_ the fix is for
  2. Generate a webrev
  3. Send it to the right mailing list for review
  4. Make changes as requested by upstream and update webrev
  5. A sponsor will push your fix for you

As you can see, it's not a very complicated process. Most of the delays in
patch acceptance have been when the patch is non-trivial or has unexpected
issues (even if those issues are known only Oracle-internal and can only be
guessed by those of us outside) or someone sufficiently qualified to review
the patch is not available.

One thing to note: Oracle requires signing a Contributor License Agreement
before they will accept non-trivial patches.

## Identify the Group or Poject


The first thing to do if you want to send a fix upstream is to identify what
_Group_ or _Project_ it is for. For this purpose, both groups and projects are
more-or-less the same (groups are more general). They consist of a collection
of people who care about something. For example, some folks care about the
`javac` compiler, some others cares about the build system and others that
care about ports to different architectures. There is a list of these groups
and projects available on the OpenJDK web page, on the left side.

Simply look through them and try to pick what you think is the best project or
group for your fix. Some groups and projects are obvious: if you are fixing
something in swing, that's the Swing group. If you want to fix something in
the ARMv8 port, that's the aarch64 project. If you can't find the best group,
you can fall back to Core Libraries if it's a patch for the standard java
library (that is, a fix for a java.* or javax.* class) or you can fall back to
Hotspot if it is a fix for hotspot.

Make a note of the mailing list(s) and repositories used by the group.

Don't worry if you can't find the ideal group, project or repository; someone
will point you in the right direction in later on, but it may mean (slightly)
more work later.

## Generate a webrev


Since you are trying to submit a patch upstream, I will assume you already
have a fix for it. The first thing you need to do is to get the latest OpenJDK
code using the most appropriate repository. And then make your fix. Once you
have built and tested your fix, you can generate a patch for review. OpenJDK
uses a custom tool called webrev to generate easier-to-reivew patches.

Assuming you are making a fix to hotspot, use it like so:

    cd jdk8/hotspot
    ksh ../make/scripts/webrev.ksh

This program will look for changes in the current repository and generate a
bunch of files. You should see a new
webrev.zip file and a webrev directory. The webrev directory should contain an
index.html file that should look roughly like this existing one

Upload the webrev directory somewhere publicly where anyone who wants to
review the patch can see it. A public dropbox folder works just fine, as done
any personal webspace that you may have. Regular contributors to OpenJDK
generally use cr.openjdk.java.net.

## Send mail with patch

Now you need to send an email describing the patch and what it's fixing to the
right OpenJDK mailing list. remember to subscribe to the mailing list first,
though.

Use a descriptive subject in the email, prefixing it with "RFR" (or Request
for Review). Link to the public webrev in the email.

## Make changes and update webrev

Hopefully, someone will review the patch quickly (depending on the fix, you
may get a response within the hour or it may take a few days).

The reviewer may suggest improvements or additional fixes. They may also
request additional cleanup or testing as well.

## A Sponsor will push the fix

Once upstream is happy with the patch, a sponsor will ask you for a changeset
that they can push or perhaps they will generate one for you. The details of
producing a changeset are available in the developer's guide. Since you don't
have push access, a sponsor will push the fix on your behalf to the
appropriate repository. It will probably take a few weeks until that change
makes it from group repository to integration repository to the master
repository (`jdk8/jdk8`).

And that's it! So don't be afraid to propose patches for OpenJDK :)

Complete details about all this process is available, of course, in the
Developer's Guide.


