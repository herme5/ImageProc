#!/bin/sh

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR"/..)"
cd "$PROJECT_ROOT" || exit 1

set -e
version=`./Scripts/get_version.sh`

echo "\n* Saving current changes"
git stash

echo "\n* Update local master"
git fetch
git checkout master >/dev/null 2>&1
git pull
git checkout - >/dev/null 2>&1

echo "\n* Rebasing 'develop' onto 'master'"
git checkout develop >/dev/null 2>&1
git pull
git reset --hard origin/master
git push --force origin develop
git checkout - >/dev/null 2>&1

echo "\n* Tagging"
git checkout master >/dev/null 2>&1
git tag "$version"
git push origin master --follow-tags
git checkout - >/dev/null 2>&1

cd - >/dev/null || exit 1
