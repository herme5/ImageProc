#!/bin/sh

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR"/..)"
cd "$PROJECT_ROOT" || exit 1

set -e
version=`./Scripts/get_version.sh`

echo "\n* Saving current changes"
git stash

echo "\n* Rebasing 'develop' onto 'master'"
git checkout develop >/dev/null 2>&1
git rebase master
git checkout - >/dev/null 2>&1

echo "\n* Tagging"
git checkout master
git tag "$version"
git push --folow-tags
git checkout - >/dev/null 2>&1

echo "\n* Restoring previous state"
git stash pop

cd - >/dev/null || exit 1
