#!/usr/bin/env bash

SCRIPTS=( 00__check_ulimit.sh 01__build_RHAMT.sh 02__analyze_apps.sh )

for SCRIPT in "${SCRIPTS[@]}"
do
  echo ">>> ${SCRIPT}"
  source ${SCRIPT}
  echo "<<< ${SCRIPT}"
done
