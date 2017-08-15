#!/bin/bash

# RHAMT github repository
# => "Maarc" is the report with the latest corrected rules
# => "windup" is the official repo
RHAMT_BASE_REPO="Maarc"

# Current directory
DIR_CURRENT=$(pwd)

# Directory with the source code
DIR_GIT_CODE="${DIR_CURRENT}/01__RHAMT_code"
DIR_DIST="${DIR_CURRENT}/01__RHAMT"

# Maven build parameters
MVN_ARGS='-U clean install'

# Clone the ${1} GitHub repostory.
function git_clone() {
  echo ">>> Checkout '${1}/${2}'"
  if [ -d "${DIR_GIT_CODE}/${2}" ]; then
    # git pull if the directory exists
    cd ${DIR_GIT_CODE}/${2}
    git pull
  else
    # otherwise full checkout
    cd ${DIR_GIT_CODE}
    git clone --depth 1 -b master "https://github.com/${1}/${2}.git"
  fi
}

# Builds the maven project in ${1} skipping the tests.
function mvn_t() {
  echo ">>> Build '${1}' (without executing tests)"
  mvn -f ${DIR_GIT_CODE}/${1}/pom.xml ${MVN_ARGS} -Dmaven.test.skip=true -DskipTests ${2}|| { echo "Issue while executing 'mvnt' in ${1}"; kill -INT $$; }
}

# Builds the maven project in ${1} without skipping the tests.
function mvn_a() {
  echo ">>> Build '$1'"
  mvn -f ${DIR_GIT_CODE}/$1 ${MVN_ARGS} || { echo "Issue while executing 'mvna' in $1"; kill -INT $$; }
}

function main() {

  mkdir -p ${DIR_GIT_CODE}

  # Checkout source code from GitHub

  git_clone ${RHAMT_BASE_REPO} "windup-keycloak-tool"
  git_clone ${RHAMT_BASE_REPO} "windup-web"
  git_clone ${RHAMT_BASE_REPO} "windup-web-distribution"

  # Pass additional arguments to not execute tests
  mvn_t "windup-keycloak-tool"
  mvn_t "windup-web" "-pl !:windup-tests-e2e,!tests"
  mvn_t "windup-web-distribution"

  DIST=$(find ${DIR_GIT_CODE} -type f -name "rhamt-web-distribution*.zip" -exec echo {} \;)
  echo ">>> RHAMT built successfully in ${DIST}"

  cd ${DIR_CURRENT}
}

main
