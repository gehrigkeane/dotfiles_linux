#!/usr/bin/env bash

source ./log.sh

#
# Functions
#

parse_install () {
  #
  # Parse an _install_ file, and output a space delimited string to stdout
  #
  # Args: Expects exactly one argument whose value is an existing file
  #
  if [ $# != 1 ] ; then
    error "Please provide exactly one argument to an existing _install_ file"
    exit 1
  elif [ ! -f "$1" ] ; then
    error "Please ensure that $DIR/$1 exists and is a file"
    exit 1
  fi

  PACKAGES=""
  while IFS= read -r LINE; do
    # Truncate LINE on '#' 
    PACKAGE="$( printf $LINE | tr -d '#' )"
    PACKAGES="$PACKAGES $PACKAGE"
  done < $1

  printf "$PACKAGES"
}
