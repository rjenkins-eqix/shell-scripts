#!/bin/sh
#
# Shell script template including support for:
#   lock file - bail if another instance of script is running ("-f" to ignore)
#   stop file - use "-K" to create, "-S" to remove ("-f" to ignore)
#
# Update:
#   Help message
#   BASEDIR, LOCKDIR and STOPDIR
#

SCRIPTNAME=`basename $0`
DATESTAMP=`date`
VERBOSE=

BASEDIR=/var/tmp
LOCKDIR=${BASEDIR}/.LCK_${SCRIPTNAME}
STOPDIR=${BASEDIR}/.STP_${SCRIPTNAME}

PATH=$PATH:/opt/local/bin

#
# Function definitions
#

# Function to run on script exit, whether successful or not
on_exit () {
  # Check to see if the lock should be removed on exit (ie, don't remove
  # the lock established by another instance of the script)
  if [ -e ${LOCKDIR} ]; then
    [ "${RMLOCK}" ] && rmdir ${LOCKDIR}
  fi
}

# Print usage and help message
usage () {
  echo "Usage: ${SCRIPTNAME} [-fhKSv]"
  if [ "$1" ]; then
    cat <<EOH
Wrapper script for 
  -f	Force execution (ignore stop and lock files)
  -h	This message
  -S	Remove stop file
  -K	Create stop file
  -v	Verbose output

EOH
  fi
}

# Only output message if verbose mode selected
log_verbose () {
  if [ "${VERBOSE}" ]; then
    echo "$*"
  fi
}

# Send output message to stderr
log_error () {
  echo "ERROR - $*" >&2
}

#
# Option handling
#

FORCE= MKSTOP= RMSTOP= VERBOSE= RMLOCK=1
while getopts fhKqSv OPT; do
  case ${OPT} in
    f) FORCE=1
       ;;
    h) usage 1
       exit 0
       ;;
    v) VERBOSE=1
       ;;
    S) RMSTOP=1
       ;;
    K) MKSTOP=1
       ;;
    *) usage >&2
       exit 1
       ;;
  esac
done
shift $((${OPTIND} - 1))

#
# Stop and lock file handling
#

# Check options for sanity
if [ "${MKSTOP}" -a "${RMSTOP}" ]; then
  log_error "Error: -K and -S mutually exclusive"
  usage >&2
  exit 1
fi

# Remove STOPDIR?
if [ "${RMSTOP}" ]; then
  if [ -e "${STOPDIR}" ]; then
    rmdir ${STOPDIR}
    log_verbose "Removed stopfile"
  else
    log_error "No stopfile found"
    exit 2
  fi

  # Always exit on -K
  exit 0
fi

# Create STOPDIR?
if [ "${MKSTOP}" ]; then
  if [ -e "${STOPDIR}" ]; then
    log_error "Stopfile already exists"
    exit 2
  else
    mkdir ${STOPDIR}
    log_verbose "Created stop file - ${SCRIPTNAME} will not run (-f to ignore, -S to remove)"
  fi

  # Always exit on -S
  exit 0
fi

# mkdir will fail if LOCKDIR already exists
if mkdir ${LOCKDIR} 2>/dev/null; then
  :
else
  # Don't remove the lock from another instance on exit
  RMLOCK=
  if [ -z "${FORCE}" ]; then
    log_error "Found lockfile ${LOCKDIR} (-f to ignore)"
    exit 2
  else
    log_verbose "Ignoring lockfile"
  fi
fi

# Call function 'on_exit' when script exits
trap on_exit 0

# Bail if we find STOPDIR
if [ -d ${STOPDIR} ]; then
  if [ "${FORCE}" ]; then
    log_verbose "Ignoring stopfile (-f given)"
  else
    log_verbose "Found stopfile - exiting (-f to ignore, -S to remove)"
    exit 0
  fi
fi

log_verbose "${SCRIPTNAME} started"

#
# Do the work
#
/bin/true

log_verbose "${SCRIPTNAME} completed successfully"
exit 0

# EOF
