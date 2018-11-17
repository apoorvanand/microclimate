#!/bin/bash
#*******************************************************************************
# Licensed Materials - Property of IBM
# "Restricted Materials of IBM"
#
# Copyright IBM Corp. 2018 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
#******************************************************************************

# Script to remove the microclimate cli from its old directory located at /usr/local
# Needs to be run as sudo

# SET LIST VARIABLES
# Normal list (non-root)
DIRECTORY_LIST=(~/.microclimate ~/.mcdev);
SYMLINK_LIST=(~/microclimate ~/mcdev);
# Root list (root user only)
if [ "$EUID" -eq 0 ]; then
  DIRECTORY_LIST=(~/.microclimate ~/.mcdev /usr/local/microclimate /usr/local/mcdev);
  SYMLINK_LIST=(~/microclimate ~/mcdev /usr/local/bin/microclimate /usr/local/bin/mcdev);
fi

echo -e "\nRunning Microclimate CLI uninstaller.\n";

# REMOVE DIRECTORIES
for DIRECTORY in ${DIRECTORY_LIST[@]}; do
  REMOVAL_DIRECTORY=${DIRECTORY};
  if [ -d ${REMOVAL_DIRECTORY} ]; then
    echo "Microclimate directory found: ${REMOVAL_DIRECTORY}";
    rm -rf ${REMOVAL_DIRECTORY} >/dev/null 2>/dev/null;
    if [ $? -eq 0 ]; then
      echo "Microclimate directory removed: ${REMOVAL_DIRECTORY}";
    else
      ROOT_CHECK=$(ls -ld ${REMOVAL_DIRECTORY} | awk '{print $3}');
      if [ ${ROOT_CHECK} == 'root' ]; then
        echo "Microclimate directory ${REMOVAL_DIRECTORY} is owned by root."
        echo "Please run ./uninstall.sh as root user.   (sudo ./uninstall.sh)";
      else
        echo -e "Error removing Microclimate. \nExiting";
      fi
      exit 1;
    fi;
  fi;
done;

# REMOVE SYMLINKED FILES
for FILE in ${SYMLINK_LIST[@]}; do
  if [ -L ${FILE} ]; then
    echo "Found Microclimate symlink: ${FILE}";
    rm -if ${FILE};
    if [ $? -eq 0 ]; then
      echo "Microclimate symlink removed: ${FILE}";
    else
      echo -e "Error removing Microclimate symlink: ${FILE}\nExiting";
      exit 1;
    fi
  fi
done;

echo "Microclimate has been uninstalled.";
exit 0;
