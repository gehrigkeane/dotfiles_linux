#!/usr/bin/env bash

RED=`tput setaf 1`
GREEN=`tput setaf 2`
MAGENTA=`tput setaf 5`
RESET=`tput sgr0`

error () {
  printf "${RED}[ERROR] $1${RESET}\n" >&2
}

info_ () {
  printf "${MAGENTA}[INFO] $1${RESET}\n"
}

success () {
  printf "${GREEN}[SUCCESS] $1${RESET}\n"
}

error_exit () {
  error "System Bootstrap Failed, please refer to line $(caller)" >&2
  exit 1
}

trap error_exit ERR
