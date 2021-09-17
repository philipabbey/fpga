#!/bin/bash
#
# Create a Cygwin mirror for offline installation
# Ref: https://www.cygwin.com/package-server.html
#
# CAREFUL! Delete mess with:
#  cd ${MIRRORLOC}
#  find * -maxdepth 0 -type d | xargs rm -rf
#
# NB. Configure your Apache webserver to allow directory listings on ${MIRRORLOC}. Either
# through .htaccess or the webservers's site configuration in /etc/apache2/sites-available.
#
#  Options +Indexes
#
# Cygwin mirror site chosen from the list at https://cygwin.com/mirrors.html
MIRRORSITE="rsync://cygwin.mirror.constant.com/cygwin-ftp"
# Next Does not work
#MIRRORSITE="rsync://cygwin.mirrors.hoobly.com"
#MIRRORSITE="rsync://mirrors.kernel.org/sourceware/cygwin"
# Local directory to mirror to
MIRRORLOC="/data/website/cygwin-mirror"
# Number of dated mirrors to retain, anything older will be deleted
KEEP=3

THIS=$(realpath ${0})
SCRIPT=$(basename ${THIS})
SCRIPTDIR=$(dirname ${THIS})

# Usage: join ' , ' a b c
#        => "a , b , c"
#
# Ref: https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
#
function join() {
    local d=${1}
    shift
    local f=${1}
    shift
    printf %s "${f}" "${@/#/$d}"
}

DIR=$(date '+%Y-%m-%d-%H-%M-%S')
cd ${MIRRORLOC}

echo "Mirroring to:     ${MIRRORLOC}/${DIR}"

declare -a RSYNCOPTS=(
  "-azv"
  "--info=progress2"
)

NEWEST=$(find ${MIRRORLOC}/* -type d -prune -exec ls -d {} \; | tail -1)

mkdir -p ${MIRRORLOC}/${DIR}
cd ${MIRRORLOC}/${DIR}

# Download the installer
wget "https://cygwin.com/setup-x86_64.exe"
chmod +x setup-x86_64.exe
# Mirror the packages for installation
time for arch in noarch x86_64; do
  mkdir -p ${arch}
  # Get size estimate
  if [[ (! -z ${NEWEST}) && (-d ${NEWEST}) ]]; then
    echo "Hard linking to : ${NEWEST}/${arch}"
    # Get estimates for the transfer
    rsync --dry-run --stats       \
      $(join " " ${RSYNCOPTS[@]}) \
      --link-dest=${NEWEST}       \
      ${MIRRORSITE}/${arch}       \
      ${MIRRORLOC}/${DIR} | sed -n '/Total transferred file size/ p'
    rsync $(join " " ${RSYNCOPTS[@]}) \
      --link-dest=${NEWEST}           \
      ${MIRRORSITE}/${arch}           \
      ${MIRRORLOC}/${DIR}
  else
    rsync --dry-run --stats       \
      $(join " " ${RSYNCOPTS[@]}) \
      ${MIRRORSITE}/${arch}       \
      ${MIRRORLOC}/${DIR} | sed -n '/Total transferred file size/ p'
    rsync $(join " " ${RSYNCOPTS[@]}) \
      ${MIRRORSITE}/${arch}           \
      ${MIRRORLOC}/${DIR}
  fi
done

# Automate the deletion of old mirrors
FORDELETION=$(find ${MIRRORLOC}/* -type d -prune | xargs ls -d1t | tail -n +$((${KEEP} + 1)))

for m in ${FORDELETION}; do
  echo "Deleting mirror at: ${m}"
  rm -r ${m}
done

# Find out how much disc space we're taking up
du -sh ${MIRRORLOC}/*
