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

echo "\n* Fetching"
git fetch

# The tag is created on 'main', and the step further down hard-resets 'develop' onto it and force
# pushes. That is only safe once 'develop' has been merged into 'main'. Otherwise it discards
# every commit that exists on 'develop' alone, both locally and on the remote, and then tags the
# release at whatever stale commit 'main' happens to point at.
if ! git merge-base --is-ancestor develop origin/main; then
  echo "error: 'develop' is not merged into 'main', refusing to continue." >&2
  echo "note: $(git rev-list --count origin/main..develop) commit(s) on 'develop' would be discarded." >&2
  echo "note: merge 'develop' into 'main' first, then run this again." >&2
  exit 1
fi

echo "\n* Saving current changes"
git stash

echo "\n* Update local main"
git checkout main >/dev/null 2>&1
git pull
git checkout - >/dev/null 2>&1

echo "\n* Rebasing 'develop' onto 'main'"
git checkout develop >/dev/null 2>&1
git pull
git reset --hard origin/main
git push --force origin develop
git checkout - >/dev/null 2>&1

echo "\n* Tagging"
git checkout main >/dev/null 2>&1
git tag "$version"

# `--follow-tags` only pushes *annotated* tags, and the tag created just above is a lightweight one, so it
# used to go nowhere: the push reported "Everything up-to-date", the release looked done, and the tag only
# existed locally. 2.0.0 and 2.1.0 both had to be pushed by hand afterwards. Pushing the ref by name works
# whichever kind of tag it is.
git push origin main
git push origin "$version"

# The tag is the release, so make sure it actually landed rather than trusting the push.
if [ -z "$(git ls-remote --tags origin "refs/tags/$version")" ]; then
  echo "error: $version is not on the remote after pushing it." >&2
  exit 1
fi

git checkout - >/dev/null 2>&1

cd - >/dev/null || exit 1
