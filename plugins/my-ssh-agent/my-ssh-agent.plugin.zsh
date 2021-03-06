#!/bin/zsh
# Hey EMACS, this should be in -*- sh -*- mode
#
# sssha = Start SSH Agent
#
# Routines to modify setup ssh-agent and associated environment variables.
# This is sourced from my .bashrc file, something like this:
#   # setup ssh-agent, if appropriate
#   if [ -f "$HOME/.ssh/sssha" ]; then
#     source $HOME/.ssh/sssha
#   fi
#
# Optional args (yes, you can pass args to a sourced file) are:
#  -t <timeout>  - passed to ssh-add to set lifetime of keys added
#  -e <env-file> - file in which to store environment variables for
#                  the instnace of ssh-agent started by this script.
#                  Defaults to: $HOME/.ssh/agent-env.`hostname`
#  -k <key-file> - add a (non-standard) key file to the list of keys
#                  added via ssh-add.  The default keys added are:
#                  $HOME/.ssh/id_rsa and $HOME/.ssh/id_dsa
#  -x            - IF THIS shell starts the agent, then kill the agent
#                  when THIS shell exits.  Useful when you want to
#                  start an agent on a remote machine, but want it to
#                  go away when you log out.
#
# Works on *NIX, Mac OS-X, and Windows (Cygwin)
# but requires a relatively recent version of BASH (2.x or better)
#
# This works on Mac OS X <= 10.4, but OS X 10.5 (Leopard) introduced a
# version of ssh-agent and associated programs that 'do-the-right-thing' 
# and interact with the Mac keyring, so this is not needed there.
#
# Author: Eric Engstrom (engstrom(-AT-)m t u(-DOT-)n e t)
#
# $Id: sssha 5219 2008-12-01 17:28:53Z engstrom $
##

# debug
#cat /dev/null > /tmp/sssha-debug
#DEBUG() {  echo "sssha: $*" | tee -a /tmp/sssha-debug;  }
#DEBUG "is interactive? '$-'"
#DEBUG "args: '$*'"

# Canonicalize hostname to just the short name
if [ -z "$HOSTNAME" ]; then 
  HOSTNAME=`hostname`
fi
HOSTNAME=`echo $HOSTNAME | sed 's/\..*//'`

# Prevent stupidity - would like to do this, but other scripts I have use this
#test ! `echo "$0" | egrep 'bash$'` && \
#  echo "RTFM|RTFS! Do not execute this file - source it from your shell" && \
#  exit 1

# default file in which to store environment info
SSSHA_ENV=$HOME/.ssh/agent-env.$HOSTNAME
declare -a SSSHA_KEYS

# --- PARSE ARGS --- #
sssha_parse_args() {
  local OPTIND=1
  while getopts "xe:k:t:" OPT; do
    #echo "$OPT $OPTARG $OPTIND"
    case $OPT in
      t) SSSHA_ARGS="-t $OPTARG" ;;
      e) SSSHA_ENV="$OPTARG" ;;
      k) [ -f "${OPTARG}" ] && SSSHA_KEYS[${##SSSHA_KEYS}]="$OPTARG" ;;
      x) SSSHA_STOP_ON_EXIT=$OPT
    esac
  done
  shift $(($OPTIND - 1))

  # set default key, if none specified
  if [ -z "${#SSSHA_KEYS}" ]; then
    for key in $HOME/.ssh/id_[rd]sa; do
      [ -f "$key" ] && SSSHA_KEYS[${##SSSHA_KEYS}]="$key"
    done
  fi
}

# --- IS AN AGENT RUNNING? --- #
sssha_agent_running () {
  test `ssh-add -l >/dev/null 2>&1; echo $?` -ne 2
}

# --- STOP RUNNING AGENT --- #
sssha_stop_agent () {
  echo "Stopping ssh-agent..."
  eval `ssh-agent -k`
  /bin/rm -f ${SSSHA_ENV}
}

# --- START NEW AGENT --- #
sssha_start_agent () {
  echo "Initializing new ssh-agent..."
  ssh-agent ${SSSHA_ARGS} | sed 's/^echo/#echo/' > ${SSSHA_ENV}
  chmod 600 ${SSSHA_ENV}
  . ${SSSHA_ENV}
  # if -x option passed, since THIS shell started the agent, 
  # then stop the agent when this shell exits
  if [ "${SSSHA_STOP_ON_EXIT}" ]; then
    trap "sssha_stop_agent" EXIT
  fi
}

# --- ADD KEYS TO RUNNING AGENT --- #
sssha_add_keys () {
  # determine which keys need to be added yet
  local key
  local -a keys
  for key in "$@"; do
    # get the fingerprint for the public key; ssh-keygen should search
    # for the public key given the private key, and if the public key
    # is not found, we'll have to assume the key is not in the agent.
    # If we get a fingerprint, add the key if not already in the agent.
    fingerprint=`ssh-keygen -f ${key} -l 2>/dev/null | awk '{print $2}'`
    if [ "$?" = "0" ] && [ -n "$fingerprint" ] && \
       ! (ssh-add -l | grep "$fingerprint" > /dev/null); then
      #echo ${key} missing - ${fingerprint}
      keys+=("$key")
    fi
  done

  # return if no keys to add
  [ -z "${keys[@]}" ] && return
    
  # add the missing keys, but kill the agent if add fails
  ( trap "" SIGINT
    ssh-add "${keys[@]}" || sssha_stop_agent
  )
}

#--------------------------------------------------
# Here comes the real work:
# 1. Parse args
sssha_parse_args $*;

# 2. If we can't connect to existing (forwarded?) agent, 
#    source the existing environment cache, if available
if ! sssha_agent_running && [ -f "${SSSHA_ENV}" ]; then
  #echo "Loading '${SSSHA_ENV}'"
  . ${SSSHA_ENV}
fi

# 3. IF on an interactive shell AND there are valid keys to be had...
#if [[ "$-" == *i* ]]; then
#  echo "Reached"
  # 3.1 Start the agent if we cannot connect to it
  #DEBUG "Interactive shell and have keys..."
  sssha_agent_running || sssha_start_agent

  # 3.2 Add the keys that aren't already registered.
 # if tty -s && [[ "$-" =~ c ]]; then
    # 3.2.1 Have a TTY on an interactive, non commanded shell - ask directly
    echo "Adding missing private keys from current ssh-agent. ${SSSHA_KEYS[@]}"
    sssha_add_keys ${SSSHA_KEYS[@]}
    
#  elif [[ "$-" =~ "i" && "$-" =~ "c" && `uname -o` =~ '^Cygwin$' ]]; then
#    # 3.2.2 No tty - can we bring up a secondary window?
#    echo "NO tty - can we cygstart a shell?"
#    cygstart bash
#
#  else 
#    # 3.2.3 No way to prompt the user for the keys, so just let the agent run
#    echo "No way to query user for key passphrases - leaving agent emtpy"
#  fi
#fi

# leave this around for sssha_stop_agent
#unset SSSHA_ENV
# but unset the rest
unset SSSHA_KEYS
unset SSSHA_ARGS
unset SSSHA_STOP_ON_EXIT

##
