#!/bin/bash
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Script used to run tvOS tests.

SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(dirname "$SCRIPTS")

# Create cleanup handler
cleanup() {
  EXIT=$?
  set +e

  if [ $EXIT -ne 0 ];
  then
    WATCHMAN_LOGS=/usr/local/Cellar/watchman/3.1/var/run/watchman/$USER.log
    [ -f "$WATCHMAN_LOGS" ] && cat "$WATCHMAN_LOGS"
  fi
  # kill whatever is occupying port 8081 (packager)
  lsof -i tcp:8081 | awk 'NR!=1 {print $2}' | xargs kill
}

# Wait for the package to start
waitForPackager() {
  local -i max_attempts=60
  local -i attempt_num=1

  until curl -s http://localhost:8081/status | grep "packager-status:running" -q; do
    if (( attempt_num == max_attempts )); then
      echo "Packager did not respond in time. No more attempts left."
      exit 1
    else
      (( attempt_num++ ))
      echo "Packager did not respond. Retrying for attempt number $attempt_num..."
      sleep 1
    fi
  done

  echo "Packager is ready!"
}

runTvosTests() {
  # shellcheck disable=SC1091
  source "./scripts/.tests.tvos.env"
  xcodebuild build-for-testing -quiet \
    -workspace ios/SvgTest.xcworkspace \
    -scheme SvgTest-tvOS \
    -sdk $IOS_SDK \
    -destination "platform=$IOS_PLATFORM,name=$IOS_DEVICE,OS=$IOS_TARGET_OS"
  xcodebuild test-without-building \
    -workspace ios/SvgTest.xcworkspace \
    -scheme SvgTest-tvOS \
    -sdk $IOS_SDK \
    -destination "platform=$IOS_PLATFORM,name=$IOS_DEVICE,OS=$IOS_TARGET_OS"
}

runIosTests() {
  source "./scripts/.tests.env"
  xcodebuild build-for-testing -quiet \
    -workspace ios/SvgTest.xcworkspace \
    -scheme SvgTest \
    -sdk $IOS_SDK \
    -destination "platform=$IOS_PLATFORM,name=$IOS_DEVICE,OS=$IOS_TARGET_OS"
  xcodebuild test-without-building \
    -workspace ios/SvgTest.xcworkspace \
    -scheme SvgTest \
    -sdk $IOS_SDK \
    -destination "platform=$IOS_PLATFORM,name=$IOS_DEVICE,OS=$IOS_TARGET_OS"
}

xcprettyFormat() {
  if [ "$CI" ]; then
    # Circle CI expects JUnit reports to be available here
    REPORTS_DIR="$HOME/react-native/reports"
  else
    THIS_DIR=$(cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" && pwd)

    # Write reports to the react-native root dir
    REPORTS_DIR="$THIS_DIR/../build/reports"
  fi

  xcpretty --report junit --output "$REPORTS_DIR/junit/$TEST_NAME/results.xml"
}

preloadBundles() {
  # Preload the bundle for better performance in integration tests
  curl -s 'http://localhost:8081/index.bundle?platform=ios&dev=true' -o /dev/null
}

main() {
  cd "$ROOT" || exit

  # Start the packager
  #yarn start --max-workers=1 || echo "Can't start packager automatically" &

  #waitForPackager
  #preloadBundles

  # Build and run tests.
  runIosTests
  runTvosTests
}

trap cleanup EXIT
main "$@"
