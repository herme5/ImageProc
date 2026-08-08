#!/bin/sh

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR"/..)"
cd "$PROJECT_ROOT" || exit 1

set -e

# The version is no longer recorded anywhere in the tree: a git tag is the release. Pass the one to
# create, e.g. ./Scripts/bump.sh 2.0.0
version="$1"
if [ -z "$version" ]; then
  echo "usage: $0 <version>" >&2
  echo "note: latest tag is $(git describe --tags --abbrev=0 2>/dev/null || echo 'none')" >&2
  exit 1
fi
if [ -n "$(git tag -l "$version")" ]; then
  echo "error: $version is already tagged." >&2
  exit 1
fi

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
