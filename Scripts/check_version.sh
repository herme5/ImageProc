#!/bin/sh

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR"/..)"
cd "$PROJECT_ROOT" || exit 1

version=`./Scripts/get_version.sh`

# Check if git tag already exists
if [ $(git tag -l "$version") ]; then  
  echo "Seems that $version already tagged, consider bumping version in ImageProc.podspec". >&2
  cd - >/dev/null
  exit 1
fi

cd - >/dev/null || exit 1
