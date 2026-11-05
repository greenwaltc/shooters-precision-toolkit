#!/bin/sh
# Use Java 21+ without changing the machine's default Java installation.
set -eu

java_is_supported() {
  emulator_java_major=$("$1" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -n 1)
  [ "${emulator_java_major:-0}" -ge 21 ]
}

if ! command -v java >/dev/null 2>&1 || ! java_is_supported "$(command -v java)"; then
  emulator_java_home=""
  if [ -x /usr/libexec/java_home ]; then
    emulator_java_home=$(/usr/libexec/java_home -v 21 2>/dev/null || true)
  fi
  if [ -z "$emulator_java_home" ] || ! java_is_supported "$emulator_java_home/bin/java"; then
    if [ -d '/Applications/Android Studio.app/Contents/jbr/Contents/Home' ]; then
      emulator_java_home='/Applications/Android Studio.app/Contents/jbr/Contents/Home'
    fi
  fi
  if [ -z "$emulator_java_home" ] || ! java_is_supported "$emulator_java_home/bin/java"; then
    echo 'Firebase emulators require Java 21+. Install a JDK 21+ and add its bin directory to PATH.' >&2
    exit 1
  fi
  export JAVA_HOME="$emulator_java_home"
  export PATH="$emulator_java_home/bin:$PATH"
fi

exec npx -y firebase-tools@latest "$@"
