#!/bin/bash
# Author: Maxim Vasilev <admin@qwertys.ru>
# Description: Reinitializes speciafied (or all) databases

# Raise an error in case of unbound var
set -u
myname=`basename $0`

###
# Globs
###

# Error codes
E_MISC=20
E_ARGS=21
E_CONF=22

# Log messages
LOG_E_MISC="Unknown error occurred."
LOG_E_ARGS="Invalid arguments supplied."

###
# Functions
###

printHelp(){
    echo "Usage:
    $myname [database] - reinitialize speciafied database
    $myname all - reinitialize all databases
    $myname help - print this help message"
}

# Logging function (KO to the rescue)
logEvent() {
    timestamp=`date -R`
    log_msg="$@"

    if [[ $log_path = "stdout" ]]
    then
        echo "[$timestamp] $log_msg"
    else
        echo "[$timestamp] $log_msg" >> $log_path
    fi
}

# Panic function
errorExit() {
    exit_code=$1
    shift
    logEvent "$@"
    exit $exit_code
}

###
# main()
###

. ${DBSEED_CONF-"conf/development"}

# Enable debug?
if [[ "${debug_enabled-false}" = "true" ]]; then set -x; fi

# Redirect output
if [[ "${log_applications-false}" = "true" ]]
then
    exec >> "$log_path"
    exec 2>> "$log_path"
fi

case "${1-}" in
"ALL" )
    echo
    ;;
"help" )
    printHelp
    ;;
* )
    if [[ -s ./sql/${1}/config ]]
    then
        . ./sql/${1}/config
    else
        printHelp
        errorExit $E_ARGS $LOG_E_ARGS
    fi
    ;;
esac


exit 0 
