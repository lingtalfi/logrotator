#!/bin/bash


#----------------------------------------
# Log Rotator -- LingTalfi -- 2015-10-17
#----------------------------------------
#
# Command Line
# -------------------
# logrotator -f logFile [-d logDir] [-m rotatedFileFormat] [-c] [-s maxSize] [-r rotateValue] [-v] [-n]
# 
# - logDir: the location of the directory where the rotated files  (see 'What does this script do?' section) will reside
#             The default value is the log file Name (https://github.com/lingtalfi/ConventionGuy/blob/master/nomenclature.fileName.eng.md)
#             followed by the suffix ".d".
#             The logDir should not contain anything but log, because the script currently assumes that it is so,
#             and therefore could potentially delete any files that's in it when a rotation occurs.
#     
# - rotatedFileFormat: 
#     The default rotatedFileFormat is: {fileName}.{datetime}.{extension}
#     Where:
#         {fileName} is replaced with the file name of the logFile.
#             File name is defined here: https://github.com/lingtalfi/ConventionGuy/blob/master/nomenclature.fileName.eng.md
#         {datetime} is replaced by the datetimeStamp (2015-10-14__20-54-41) as defined here: https://github.com/lingtalfi/ConventionGuy/blob/master/convention.fileNames.eng.md
#         {extension} is replaced by the log file extension.
#         The resulting rotatedFile must not be a hidden file, because the script doesn't handle it yet.
#         
# - c: Use c option to not compress to gz format
# - maxSize: the threshold in bytes (see 'What does this script do?' section below for more information)
#                 Default is 1000000 (1Mo)
# - rotateValue: indicates how the oldest rotated files (see section below) are removed.
#                 The default value is 30, which means that the log dir will contain 30 rotated files max.
#                 You can specify two types of values:
#                     - a number: in which case it represents the maximum number of rotated files allowed
#                     - a number of days followed by the letter d (for instance 30d).
#                             This is called the max age.
#                             In this case, the logrotator script takes the current date (the date when you executed the script),
#                             and go back 30 days in the past. Any rotated file older than this (time) line is deleted.
# - v: verbose mode, use this for testing your setup or debug purpose                            
# - n: dry mode: works exactly as normal, except that it does not empty the log file.                            
#       This behaviour was useful while creating the script, and might be helpful for debugging                   
#         
#
#
# What does this script do?
# ----------------------------
#
# The log file is the file that you wish to rotate.
# The log dir is where rotated files are stored.
# Rotation is the action of copying the log file, put the copy (also called the rotated file) in the log dir, empty the log file,
# and then remove the oldest rotated files. 
# The rotated file is by default stamped with the datetime (any {datetime} tag in the rotated file is replaced with the actual date time).
# There is also an option to gz the rotated file.
# 
# You execute the script whenever you want (cron, manually, ...) and the script compares the log file size to an arbitrary threshold.
# If the log file size exceed the threshold, then the rotation is performed.
# 
# There is also an option to automatically remove oldest rotated file, either based on the number of rotated files in the log dir,
# or based on the rotated file mtime.
# 
#
# What could you use it for?
# ----------------------------- 
# 
# - define a custom php error log and be ensured that it will get rotated "properly"
# 
# 
# 
# 
# 

logFile=""
logDir=""
rotatedFileFormat='{fileName}.{datetime}.{extension}'
useGz=1
maxSize=1000000
maxSize=10
rotateValue='30'
verbose=0  
dry=0

 
error (){
    echo "$1" >&2
    if [ -n "$2" ]; then
        help
    fi
    exit 1
} 

help (){
    echo "Usage: logrotator -f logFile [-d logDir] [-m rotatedFileFormat] [-c] [-s maxSize] [-r rotateValue] [-v]"
} 


printFileSize(){
    wc -c < "$1" | xargs    
} 

log(){
    if [ 1 -eq "$verbose" ]; then
        echo -e "\e[34mlogrotator(v):\e[0m $1"
    fi
}


while getopts :cd:f:m:nr:s:v opt; do
    case "$opt" in
        c) useGz=0 ;;
        d) logDir="$OPTARG" ;;
        f) logFile="$OPTARG" ;;
        m) rotatedFileFormat="$OPTARG" ;;
        n) dry=1 ;;
        r) rotateValue="$OPTARG" ;;
        s) maxSize="$OPTARG" ;;
        v) verbose=1 ;;
    esac
done


# Check that log file and log dir are created
if [ -n "$logFile" ]; then
    if [ -f "$logFile" ]; then
        if [ -z "$logDir" ]; then
            logDir="$logFile.d"
        fi
        if [ ! -d "$logDir" ]; then
            mkdir -p "$logDir"
            if [ -0 -ne $? ]; then
                error "Could not create the logDir: $logDir"
            fi
        fi
        
        
        # Check whether or not a rotation should be executed
        logSize=$(printFileSize "$logFile")
        
        log "logFile=$logFile; logDir=$logDir; logSize=$logSize"
        
        if [ "$logSize" -ge "$maxSize" ]; then
            
            
            # finding rotated file name
            fileName="${logFile##*/}"
            if [ '.' = "${fileName:0:1}" ]; then
                ext="${fileName:1}"
            else
                ext=""
            fi
            dateTime=$(date +%Y-%m-%d__%H-%M-%S)
		    
		    
                        
            logFileName="$rotatedFileFormat";
            logFileName=${logFileName/\{extension\}/"$ext"}
            logFileName=${logFileName/\{datetime\}/"$dateTime"}
            logFileName=${logFileName/\{fileName\}/"$fileName"}
            
            # removing trailing dot if any (happens when file has no extension)
            if [ '.' = "${logFileName:${#logFileName}-1}" ]; then
                logFileName="${logFileName:0:${#logFileName}-1}"
            fi

            # copying the logFile into the log dir
            rotatedFilePath="$logDir/$logFileName"
            if [ -f "$rotatedFilePath" ]; then
                rm "$rotatedFilePath"
            fi
            cp "$logFile" "$rotatedFilePath"
            
            
            
            # do we need gz?
            withGzWord=without
            if [ 1 -eq $useGz ]; then
                gzip "$rotatedFilePath"
                withGzWord=using
            fi
            
            log "logSize exceeds max size of $maxSize bytes: executing rotation to $rotatedFilePath file, $withGzWord gz compression"
            
            
            # emptying the log file
            if [ 0 -eq "$dry" ]; then
                > "$logFile"
            fi
            
            
            # now, we rotate the log dir if necessary
            lastChar="${rotateValue:${#rotateValue}-1}"
            if [ 'd' = "$lastChar" ]; then
                
                rotateValue="${rotateValue:0:${#rotateValue}-1}"
                
                log "rotating: removing files older than $rotateValue days"
                
                # note: I used seconds for quick testing
                nbSec=$(( rotateValue * 24 * 3600 ))
                find "$logDir" -type f -mtime +${nbSec}s | xargs rm
            else
                
                log "rotating: keeping $rotateValue files max in the log directory"
                
                
                # rotate by max number of rotated files
                numberOfFiles=$(ls -1 "$logDir" | wc -l | xargs)
                if [ "$numberOfFiles" -gt "$rotateValue" ]; then
                    nbFilesToRemove=$(( numberOfFiles - rotateValue ))
                    oldDir=$(pwd)
                    cd "$logDir"
                    ls -1 | head -n "$nbFilesToRemove" | xargs rm
                    cd "$oldDir"
                fi
            fi

            
        else
            # no rotate, we do nothing special
            log "logSize does not exceeds max size of $maxSize: no rotation"
        fi        
    else
        error "logFile is not a file: $logFile"
    fi
else
    error "logFile not defined" 1
fi
	
	
	