+++
title = "SharedSecrets in OpenJDK"
date = "Fri, 22 Jun 2012 23:10:03 +0000"
author = "Omair Majid"
categories = [ "development" ]
tags = [ "openjdk" ]
aliases = [
    "/2012/06/22/sharedsecrets-in-openjdk/",
]
+++

I have always been impressed by the effort OpenJDK folks go to maintain API compatibility. I recently came across a nifty little trick that is used in the OpenJDK codebase to help achieve this goal. Behold the [SharedSecrets](http://hg.openjdk.java.net/jdk8/jdk8/jdk/file/tip/src/share/classes/sun/misc/SharedSecrets.java "Code for sun.misc.SharedSecets") class! The name of the class is a little misleading since it doesn't have anything to do with the cryptographic concepts of shared secrets. The javadocs do a (slightly) better job describing its purpose:

    /** A repository of "shared secrets", which are a mechanism for
        calling implementation-private methods in another package without
        using reflection. A package-private class implements a public
        interface and provides the ability to call package-private methods
        within that package; the object implementing that interface is
        provided through a third package to which access is restricted.
        This framework avoids the primary disadvantage of using reflection
        for this purpose, namely the loss of compile-time checking. */

In other words, it is used to make private methods public, without using
reflection! AND it works under a security manager! At first, I thought this
was too good to be true but it turns out that the concept behind it is pretty
simple. Here's how it works. Suppose we have a class with a fixed public api
and we wish to add a new method to it that we would like to be able to use
internally within the project but not provide as an api:

    public class FixedPublicApi {
      private static doFoo() { /* do something */ }
    }

We could choose to add the doFoo method to another class (in fact, it will
primarily be accessed through another class) and make it public, but let's
assume that the only way to avoid duplicating lots of code is to keep doFoo in
FixedPublicApi. First we create an interface that exposes the method we want
to be invoked:

    public interface FooHandler {
      public void doFoo();
    }

Then we modify the SharedSecrets class (or it's equivalent in our codebase),
to set the implementation for FooHandler

    public class SharedSecrets {
      private static FooHandler fooHandler;
      public static void setFoo(FooHandler handler) {
        fooHandler = handler;
      }
      public static void foo() {
        fooHandler.doFoo();
      }
    }

Finally we modify the FixedPublicApi class to install a handler:


    public class FixedPublicApi {
      static {
         SharedSecrets.setFoo(new FooHandler() {
           public void doFoo() {
             FixedPublicApi.doFoo();
           }
         }
      }

      private static doFoo() { /* do something */ }
    }

And that's it! Now we can use SharedSecrets to call the private method:

      SharedSecrets.doFoo();
    
  
Hats off to whoever came up with this great technique.

