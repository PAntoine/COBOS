# COBOS #
## Concurrent Object Based Operating System ##

The COBOS project was an operating system that I designed for my final year project for my degree. The purpose of this operating system (except for getting my degree) was to investigate the uses of persistent objects and how to use them.

 COBOS itself was never finished. It got to the stage that programs (that did not need to do disk read/writes) could be compiled in and run. A simplistic GUI did run. But in the original university project they was a couple of design flaws that were worked out in COBOS 2, but that was never written. (I wanted to write the higher levels in COPLE, but that was never finished).

 COBOS was designed for the x86 platform specifically. It made heavy use of segmentation as this made the OS very secure and made writing code (at the low level) very easy. Obviously it would have the problem of not being portable in any way. Another thing is some of the system device drivers are rather naive in their implementation, but this was a university piece, so that was not important. Also I feel I am one of the select few that thing segmentation is good processor design for secure and reliable computing, but it has now disappeared into the mists of time.

 COBOS in it's entirety was written in less then 6 months and it did the job it was supposed to do, namely get me a 1st, and was the highest graded project in the school. So it was a good project. I have on several occasions wanted to complete it, but I keep getting new ideas for what it should be used for and re-targeting it, and therefore redesigning it. It may one day see the light of day as a real OS. 

## Purpose ##
 COBOS was completely hand written in 4/486 assembler using TASM (that's Borlands assembler for those of you that are too young). Some of it should have been written in C which would have saved a lot of time. The description of how the OS is designed is in the project documentation which is detailed below. You can download the whole of the documentation and source code from here. Below are the interesting sections of the documentation in PDF format.


## Usage ##
 COBOS in its present state is not usable. The main problem is that it is DOS launched and does something very un-cleaver with the filesystem. The installer creates a 5M file that COBOS uses as its own file system. A-la win 3.1. The installer is reallt crude and use assumes that the FAT of the disk is FAT16. It does check that it is a FAT partition but that is all. I would not run that code under any circumstances (not even on a FAT 16 disk I have got paranoid in my old age). It did execute fine when it was created but age and changes in software and disks makes this code very obsolete and dangerous.

 But, before that to use COBOS all you did was install it, and then call COBOS from the DOS prompt and that was it. It took over your system, and if you were lucky it would return to dos on completion. (I did not have enough time to create a full memory copy program to completely save the HIGH MEM state, which I used in COBOS). 

## Improvements ##
1. Complete re-write. 
2. Some of this is covered in the COBOS 2 specification (obviously not complete) but the object paradigm is wrong. It is based on a class type, where each object belongs to a single class. Also the data and services that the object use as tied to the class. This is wrong. The objects should belong to sets that have certain requirements for data items and provide services. When an object is attached/joins a set then the object should be extended to have the extra data items that set requires it to have. (Arguably, these should be removed when the object leaves). This does not stop each object also having its own services and data-items. This makes the whole system more flexible. It also means that object do not need to be amended directly. 
3. The low level design should be processor/computer independent. 
4. Add specifics for handling the distributed aspect of the system. 
5. A much better scheduling algorithm. The one I used was out of date when I wrote it, so it must geriatric by now.

