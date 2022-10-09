#!/bin/bash
# More safety, by turning some bugs into errors.
# Without `errexit` you don’t need ! and can replace
# ${PIPESTATUS[0]} with a simple $?, but I prefer safety.
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
  echo 'I’m sorry, `getopt --test` failed in this environment.'
  exit 1
fi

# option --output/-o requires 1 argument
LONGOPTS=apionly,name:,push,rbanos,repo:,webapp,withapi
OPTIONS=An:pr:wa

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  # e.g. return value is 1
  #  then getopt has complained about wrong arguments to stdout
  exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

webapp=y
name=[YOUR-NAME]
push=n
repo=n
withapi=n
# now enjoy the options in order and nicely split until we see --
while true; do
  case "$1" in
    -a|--apionly)
      webapp=n
      withapi=y
      shift
      ;;
    -w|--withapi)
      withapi=y
      shift
      ;;
    -n|--name)
      name="$2"
      shift 2
      ;;
    -p|--push)
      push=y
      shift
      ;;
    --rbanos)
      name="Roberto A Baños Alvarez"
      repo=rbanos-mv
      shift
      ;;
    -r|--repo)
      repo="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Programming error"
      exit 3
      ;;
  esac
done

# handle non-option arguments
if [[ $# -ne 1 ]]; then
  echo "$0: A project name is required."
  exit 4
fi

if [[ $repo = "n" ]]; then
  push=n
fi

# ###########################################################
