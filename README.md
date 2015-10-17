LogRotator
===============
2015-10-17




What is it about?
-----------------------

It's about rotating one file.<br>
By that I mean: it's about controlling the growth of a file.<br>
Typically, a log file, because a log file keeps growing in size.


Now what can you do with the logRotator?
-------------------------------------------

Well, you can rotate that log file.


How does it work?
---------------------

When you execute the logRotator script, it checks the size of your logFile.
If that size exceeds an arbitrary threshold, logRotator copies your log file into an arbitrary log directory,
and then empties your log file.
It also ensures that the log directory doesn't grow out of control.

![logRotator overview](http://s19.postimg.org/y3x1ltzmr/log_Rotator.jpg)




Command Line Usage
-----------------------


Command Line
-------------------

```bash
logrotator -f logFile [-d logDir] [-m rotatedFileFormat] [-c] [-s maxSize] [-r rotateValue] [-v] [-n]
```


- logFile: the location of the log file on your filesystem
- logDir: the location of the directory where the rotated files  (see 'What does this script do exactly?' section) will reside
            The default value is the log's [file Name](https://github.com/lingtalfi/ConventionGuy/blob/master/nomenclature.fileName.eng.md)
            followed by the suffix ".d".<br>
            The logDir should not contain anything but log, because the script currently assumes that it is so,
            and therefore could potentially delete any files that's in it when a rotation occurs.
    
- rotatedFileFormat: 
    The default rotatedFileFormat is: {fileName}.{datetime}.{extension}
    Where:
        {fileName} is replaced with the file name of the logFile.<br>
            File name is defined [here]( https://github.com/lingtalfi/ConventionGuy/blob/master/nomenclature.fileName.eng.md).<br>
        {datetime} is replaced by the datetimeStamp (2015-10-14__20-54-41) as defined [here]( https://github.com/lingtalfi/ConventionGuy/blob/master/convention.fileNames.eng.md).<br>
        {extension} is replaced by the log file extension.<br>
        The resulting rotatedFile must not be a hidden file, because the script doesn't handle it yet.
        
- c: Use c option to not compress to gz format
- maxSize: the threshold in bytes (see 'What does this script do exactly?' section below for more information).<br>
                Default is 1000000 (1Mo)
- rotateValue: indicates how the oldest rotated files (see section below) are removed.<br>
                The default value is 30, which means that the log dir will contain 30 rotated files max.<br>
                You can specify two types of values:<br>
                
    - a number: in which case it represents the maximum number of rotated files allowed.
    - a number of days followed by the letter d (for instance 30d).
    
            This is called the max age.
            In this case, the logrotator script takes the current date (the date when you executed the script),
            and go back 30 days in the past. Any rotated file older than this (time) line is deleted.
                            
- v: verbose mode, use this for testing your setup or debug purpose                            
- n: dry mode: works exactly as normal, except that it does not empty the log file.                            
      This behaviour was useful while creating the script, and might be helpful for debugging                   
        
        
        
What does this script do exactly?
----------------------------

The log file is the file that you wish to rotate.<br>
The log dir is where rotated files are stored.<br>
Rotation is the action of copying the log file, put the copy (also called the rotated file) in the log dir, empty the log file,
and then remove the oldest rotated files. <br>
The rotated file is by default stamped with the datetime (any {datetime} tag in the rotated file is replaced with the actual date time).<br>
There is also an option to gz the rotated file.

You execute the script whenever you want (cron, manually, ...) and the script compares the log file size to an arbitrary threshold.<br>
If the log file size exceed the threshold, then the rotation is performed.

There is also an option to automatically remove oldest rotated file, either based on the number of rotated files in the log dir,
or based on the rotated file mtime.




Bonus
------------

Lightweight: about 200 lines of code only 

