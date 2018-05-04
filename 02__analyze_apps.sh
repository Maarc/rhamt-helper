#!/usr/bin/env bash
#set -x

# Maximum Java Heap (example: 2048m)
export MAX_MEMORY="9216m"
# Maximum Metaspace size (example: 256m)
export MAX_METASPACE_SIZE="1024m"
# Decompiled Java packages (for example PACKAGES="nl de")
PACKAGES=""
# RHAMT analysis targets
TARGET="cloud-readiness eap:7 linux"
#TARGET=" "

DIR_CURRENT=$(pwd)
RHAMT_HOME=${DIR_CURRENT}/01__RHAMT
APP_DIR_IN=${DIR_CURRENT}/02__apps
PROJECT_DIR_OUT=${DIR_CURRENT}/02__reports

VERSION=$(find ${RHAMT_HOME} -maxdepth 1 -mindepth 1 -name "*-version.txt" -type f -exec cat {} \;)

# Analyse all applications present in the ${1} directory.
function analyze() {
 	echo "==> Analyzing '${1}' ..."
 	SUB_DIR_NAME=$(echo ${1}  | rev | cut -d'/' -f1 | rev)

	TIMESTAMP=$(date +%Y_%m_%d__%H_%M_%S)
 	PROJECTS_DIR_NAME=apps-${SUB_DIR_NAME}

	APP_DIR_IN=${1}
	APP_DIR_OUT=${PROJECT_DIR_OUT}/${TIMESTAMP}__${VERSION}__${PROJECTS_DIR_NAME}
	LOG_FILE=${PROJECT_DIR_OUT}/result__${TIMESTAMP}__${VERSION}__${PROJECTS_DIR_NAME}.log

	mkdir -p ${APP_DIR_OUT}
	rm -f ~/.rhamt/log/*
	(time ${RHAMT_HOME}/bin/rhamt-cli -b --target ${TARGET} --input ${APP_DIR_IN} --output ${APP_DIR_OUT} --overwrite --packages ${PACKAGES} --enableTattletale -d) >> ${LOG_FILE} 2>&1
	echo "   Open this file for the results: ${APP_DIR_OUT}/index.html"
 	echo ""
}

function main() {
  # Check ulimit
  source 00__check_ulimit.sh
  for dir in $(find ${APP_DIR_IN} -maxdepth 1 -mindepth 1 -type d ); do
    analyze ${dir}
  done
}

main
