#!/bin/bash
#####################################################################
# NAME
#    myips
#
# SYNOPSIS
#    myips [-i {interval}]
#
# DESCRIPTION
#    For Mac OS X, this will print the time, primary interface, 
#    status of the interface, private IP, and public IP
#
#              If you provide no options, it will
#              produce these values once and then exit.
#
#              The "-i" option, followed with an integer
#              will produce a continuous loop with an
#              interval equal to the integer argument you
#              provide.  Example: myips -i 30
#
#####################################################################
# REVISIONS:
#  2017/09/28  DW  added LASTIP and MODIFIED
#  2017/09/28  DW  created func for interface and status
#  2017/09/28  DW  creation date
#
#####################################################################
#set -x
#set +x

# VARIABLES
LOGFILE=/tmp/myips.out
LASTIP="$(cat $LOGFILE)"
MODIFIED="$(stat -f "%Sm" $LOGFILE)"
cat /dev/null > $LOGFILE

# FUNCTIONS
usage() {
    echo "Usage: "
    echo "     no options will display the time, private IP,"
    echo "     public IP and then exit."
    echo ""
    echo "     -i followed by an integer will loop by that interval."
    echo ""
    exit 0
}

Time() {
  t0=$(date "+%b %d %H:%M:%S %Y")
}

Interface() {
  en=$(netstat -rn | awk '{ if ($1 ~/default/) {print $6}}')
}

Status() {
  Interface
  STAT=$(ifconfig ${en} | awk '{ if ($1 ~/status/) {print $NF}}')
}

PublicIP() {
  PubIP=$(dig +short myip.opendns.com @resolver1.opendns.com | tee -a "${LOGFILE}")
}

PrivateIP() {
  Interface
  PriIP=$(ipconfig getifaddr ${en})
}

#   GETOPTS
while getopts ":i:" opt; do
    case $opt in 
        i)  INTERVAL="${OPTARG}"
            ;;
        *)  usage
            ;;
    esac
done
shift $(($OPTIND - 1))

# RUN ONCE
if [ -n "${INTERVAL}" ]; then
  clear
else
  Time
  Interface
  Status
  PrivateIP
  PublicIP
  printf "Command last run:\t${MODIFIED}\n"
  printf "Public IP was:\t\t$(cat $LOGFILE)\n\n"
  printf "Time:\t\t\t${t0}\nInterface:\t\t${en}\nStatus:\t\t\t${STAT}\n"
  printf "Private IP:\t\t${PriIP}\nPublic IP:\t\t${PubIP}\n"
  #cat /dev/null > $LOGFILE
  exit 0
fi

# CONTINUOUS LOOP
while :;do
  printf "\n\tDate/Time\t\t   Public IP\n"
  printf "  ==============================================\n"
  COUNTER=0
  while [ $COUNTER -lt 24 ]; do
    Time
    PublicIP
    printf "  ${t0}\t\t${PubIP}\n"
    let COUNTER=COUNTER+1
    sleep $INTERVAL
    cat /dev/null > ${LOGFILE}
  done
done

# END
