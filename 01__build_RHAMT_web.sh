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

EAP_DIST_DIR="PATH_TO_BE_SET"

# Maven build parameters
MVN_ARGS='-q -U clean install'

# Patch and import JBoss EAP distribution in local maven repository
function import_jboss_eap() {

    echo ">>> Import JBoss EAP"
    EAP_VERSION=7.0.7
    EAP_BASIS=jboss-eap-7.0.0.zip
    EAP_PATCH=jboss-eap-${EAP_VERSION}-patch.zip
    EAP_DIR=jboss-eap-7.0

    EAP_BASIS_FULL=${EAP_DIST_DIR}/${EAP_BASIS}
    EAP_PATCH_FULL=${EAP_DIST_DIR}/${EAP_PATCH}

    EAP_G=org.jboss
    EAP_A=eap-dist
    EAP_V=${EAP_VERSION}
    EAP_P=zip
    EAP_GAVP=${EAP_G}:${EAP_A}:${EAP_V}:${EAP_P}

    mvn dependency:get -Dartifact=${EAP_GAVP} -o -q 2>&1 >> /dev/null
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "Missing local maven artifact for JBoss EAP ${EAP_VERSION} (${EAP_GAVP})";

      if [ -e ${EAP_BASIS_FULL} ] && [ -e ${EAP_PATCH_FULL} ]; then
        # Unpack Red Hat JBoss EAP 7

        TMP_DIR=${DIR_CURRENT}/tmp
        mkdir ${TMP_DIR}
        unzip ${EAP_BASIS_FULL} -d ${TMP_DIR} 2>&1 >> /dev/null

        # Set JBOSS_HOME
        export JBOSS_HOME="${TMP_DIR}/${EAP_DIR}"

        # Patch Red Hat JBoss EAP 7 to the latest version (should output “success” in a JSON structure)
        ${JBOSS_HOME}/bin/jboss-cli.sh "patch apply ${EAP_PATCH_FULL}"

        # Zip patched version
        cd tmp
        zip -r jboss-eap-${EAP_VERSION}.zip ${EAP_DIR}  2>&1 >> /dev/null

        # Import patched version
        mvn install:install-file -Dfile=${TMP_DIR}/jboss-eap-${EAP_VERSION}.zip -DgroupId=${EAP_G} -DartifactId=${EAP_A} -Dversion=${EAP_V} -Dpackaging=${EAP_P}
        cd ${DIR_CURRENT}

        # Cleanup
        rm -Rf ${TMP_DIR}

      else
        echo "ERROR: Please make sure that 'EAP_DIST_DIR' (${EAP_DIST_DIR}) contains the following JBoss EAP binaries:"
        echo " -> ${EAP_BASIS}"
        echo " -> ${EAP_PATCH}"
        exit 1
      fi

    else
      echo "Detected local maven artifact for JBoss EAP ${EAP_VERSION} (${EAP_GAVP})";
    fi

}

# Clone the ${1} GitHub repostory.
function git_clone() {
  echo ">>> Checkout '${1}/${2}'"
  if [ -d "${DIR_GIT_CODE}/${2}" ]; then
    # git pull if the directory exists
    cd ${DIR_GIT_CODE}/${2}
    echo "git pull"
    git pull
  else
    # otherwise full checkout
    cd ${DIR_GIT_CODE}
    echo "git clone --depth 1 -b master \"https://github.com/${1}/${2}.git\""
    git clone --depth 1 -b master "https://github.com/${1}/${2}.git"
  fi
}

# Builds the maven project in ${1} skipping the tests.
function mvn_t() {
  echo ">>> Build '${1}' (without executing tests)"
  echo "mvn -f ${DIR_GIT_CODE}/${1}/pom.xml -Dmaven.test.skip=true -DskipTests ${2} ${MVN_ARGS}"
  mvn -f ${DIR_GIT_CODE}/${1}/pom.xml -Dmaven.test.skip=true -DskipTests ${2} ${MVN_ARGS} 2>&1 >> /dev/null || { echo "Issue while executing 'mvnt' in ${1}"; kill -INT $$; }
}

function main() {

  import_jboss_eap

  mkdir -p ${DIR_GIT_CODE}

  # Checkout source code from GitHub
  git_clone ${RHAMT_BASE_REPO} "windup-keycloak-tool"
  git_clone ${RHAMT_BASE_REPO} "windup-web"
  git_clone ${RHAMT_BASE_REPO} "windup-web-distribution"

  # Pass additional arguments to not execute tests
  mvn_t "windup-keycloak-tool"
  mvn_t "windup-web" "-pl !:windup-tests-e2e,!tests"
  mvn_t "windup-web-distribution"

  DIST=$(find -L ${DIR_GIT_CODE} -type f -name "rhamt-web-distribution*.zip" -exec echo {} \;)
  echo ">>> RHAMT built successfully in ${DIST}"

  cd ${DIR_CURRENT}
}

main
