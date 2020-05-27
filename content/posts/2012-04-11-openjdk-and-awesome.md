+++
title = "OpenJDK and Awesome"
date = "Wed, 11 Apr 2012 23:08:41 +0000"
author = "Omair Majid"
aliases = [
    "/2012/04/11/openjdk-and-awesome/",
]
+++
I have been playing around with [awesome](http://awesome.naquadah.org/ "awesome") and ran into some issues with Java programs (apparently [others users are running into those problems too](http://awesome.naquadah.org/wiki/Problems_with_Java)). I hacked together a patch against [OpenJDK7](http://hg.openjdk.java.net/jdk7u/jdk7u-dev/jdk "jdk7u-dev/jdk") that seems to solve all my issues:
    
    
    diff --git a/src/solaris/classes/sun/awt/X11/XWM.java b/src/solaris/classes/sun/awt/X11/XWM.java  
    --- a/src/solaris/classes/sun/awt/X11/XWM.java  
    +++ b/src/solaris/classes/sun/awt/X11/XWM.java  
    @@ -102,7 +102,8 @@  
             METACITY_WM = 11,  
             COMPIZ_WM = 12,  
             LG3D_WM = 13,  
    -        CWM_WM = 14;  
    +        CWM_WM = 14,  
    +        AWESOME_WM = 15;  
         public String toString() {  
             switch  (WMID) {  
               case NO_WM:  
    @@ -131,6 +132,8 @@  
                   return "LookingGlass";  
               case CWM_WM:  
                   return "CWM";  
    +          case AWESOME_WM:  
    +              return "awesomewm";  
               case UNDETERMINED_WM:  
               default:  
                   return "Undetermined WM";  
    @@ -573,8 +576,12 @@  
     //                            getIntProperty(XToolkit.getDefaultRootWindow(), XAtom.XA_CARDINAL)) == 0);  
         }  
       
    +    static boolean isAwesomeWM() {  
    +        return isNetWMName("awesome");  
    +    }  
    +  
         static boolean isNonReparentingWM() {  
    -        return (XWM.getWMID() == XWM.COMPIZ_WM || XWM.getWMID() == XWM.LG3D_WM || XWM.getWMID() == XWM.CWM_WM);  
    +        return (XWM.getWMID() == XWM.COMPIZ_WM || XWM.getWMID() == XWM.LG3D_WM || XWM.getWMID() == XWM.CWM_WM || XWM.getWMID() == XWM.AWESOME_WM);  
         }  
       
         /*  
    @@ -754,6 +761,8 @@  
                     awt_wmgr = CWM_WM;  
                 } else if (doIsIceWM && isIceWM()) {  
                     awt_wmgr = XWM.ICE_WM;  
    +            } else if (isAwesomeWM()) {  
    +                awt_wmgr = XWM.AWESOME_WM;  
                 }  
                 /*  
                  * We don't check for legacy WM when we already know that WM  
      
      
    

  
  
Given the [effort it's taking to push a fix for mutter](http://thread.gmane.org/gmane.comp.java.openjdk.awt.devel/1698 "path review thread") (the default gnome3 window manager), I wouldnt hold my breath waiting for this code to make it upstream.


