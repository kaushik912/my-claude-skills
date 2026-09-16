In JDK 21, the command-line jfr view tool provides over 70 predefined views to analyze recordings directly from your terminal. [1, 2] 
Depending on what is causing your OutOfMemoryError, the best <view_name> options to run are:
## 1. For Java Heap Leaks
If your application is slowly running out of memory due to objects surviving garbage collection, use the memory leak tracking view:

jfr view memory-leaks-by-class recording.jfr


* 
* What it does: Aggregates OldObjectSample events to show you which specific classes are accumulating on the heap over time and refusing to be garbage collected. [2] 
* 

## 2. For Rapid Heap Exhaustion / High Allocation Pressure
If your application crashes quickly because threads are allocating memory faster than the GC can clean it up, use the allocation views:

jfr view allocation-by-site recording.jfr

jfr view allocation-by-class recording.jfr

jfr view allocation-by-thread recording.jfr


* 
* What they do: Breakdown memory allocation inside and outside Thread Local Allocation Buffers (TLABs). This pinpoints exactly where in your code or which thread is spamming memory. [3] 
* 

## 3. For Garbage Collection Health
To see how hard the GC was fighting just before the OOM occurred (e.g., consecutive Full GCs clearing 0 bytes), check the general GC views:

jfr view gc recording.jfr

jfr view gc-pauses recording.jfr


* 
* What they do: Show garbage collection frequencies, durations, and heap sizes before/after GC phases. [1, 2] 
* 

## 4. For Native / Off-Heap Memory Leaks
If you have Native Memory Tracking (NMT) enabled (-XX:NativeMemoryTracking=summary or detail), you can check if the OOM is occurring outside the Java heap using:

jfr view native-memory-committed recording.jfr

jfr view native-memory-reserved recording.jfr

------------------------------
## Alternative: Run it Live via jcmd
If the application is still running and experiencing memory pressure, you don't even have to dump a .jfr file. You can query the live JVM using: [2] 

jcmd <PID> JFR.view memory-leaks-by-class

Would you like to see how to adjust the formatting options (like --width or --verbose) for these views, or do you need the exact syntax to configure Old Object Sampling in production?

[1] [https://www.oracle.com](https://www.oracle.com/java/technologies/javase/21-relnote-issues.html)
[2] [https://www.oracle.com](https://www.oracle.com/java/technologies/javase/21-relnote-issues.html)
[3] [https://docs.oracle.com](https://docs.oracle.com/en/java/javase/18/troubleshoot/troubleshoot-performance-issues-using-jfr.html)
