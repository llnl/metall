#!/bin/bash
set -e

module load ${COMPILER}/${COMPILER_VERSION}

if [[ -z "${CI_JOB_ID}" ]]; then
  echo "Error: This script expect CI_JOB_ID env variable to be set."
  exit 1
fi
CI_JOB_IDENTIFIER="${CI_JOB_NAME}_${CI_JOB_ID}"

if [[ -z "${METALL_TEST_DIR_BASE}" ]]; then
  echo "Error: This script expect METALL_TEST_DIR_BASE env variable to be set."
  exit 1
fi
if [[ -z "${METALL_BUILD_DIR_BASE}" ]]; then
  echo "Error: This script expect METALL_BUILD_DIR_BASE env variable to be set."
  exit 1
fi
export METALL_TEST_DIR="${METALL_TEST_DIR_BASE}_${CI_JOB_IDENTIFIER}"
export METALL_BUILD_DIR="${METALL_BUILD_DIR_BASE}_${CI_JOB_IDENTIFIER}"

TEST_TYPE=${TEST_TYPE:-"build_and_test"}

echo "Build and test on ${HOSTNAME}"
echo "METALL_TEST_DIR=${METALL_TEST_DIR}"
echo "METALL_BUILD_DIR=${METALL_BUILD_DIR}"
echo "TEST_TYPE=${TEST_TYPE}"
echo "gcc version: $(gcc --version | head -n 1)"

if [[ -n "${BOOST_UNCOMPRESS}" && "${BOOST_UNCOMPRESS}" == "true" ]]; then
  BOOST_EXTRACT_DIR="/dev/shm/metall_ci_boost_${CI_JOB_IDENTIFIER}"
  echo "Uncompressing Boost to ${BOOST_EXTRACT_DIR}"
  mkdir -p "${BOOST_EXTRACT_DIR}"
  tar xf "${BOOST_PATH}" -C ${BOOST_EXTRACT_DIR} --strip-components 1
  export METALL_CMAKE_ADDITIONAL_OPTIONS="-DBOOST_INCLUDE_ROOT=${BOOST_EXTRACT_DIR}"
else
  export METALL_CMAKE_ADDITIONAL_OPTIONS="-DBOOST_FETCH_URL=${BOOST_PATH}"
fi

if [[ "${TEST_TYPE}" == "consumer_smoke" ]]; then
  bash ./scripts/CI/run_ci_install_tree_consumer_smoke_test.sh
else
  bash ./scripts/CI/run_ci_build_and_test.sh
fi
