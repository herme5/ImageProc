#!/bin/sh

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR"/..)"
cd "$PROJECT_ROOT" || exit 1

var_name="spec.version"
file_name="$PROJECT_ROOT/ImageProc.podspec"

# Exctract version
while IFS= read -r line && [ -z "$version" ] ; do
  if [[ $line == **"$var_name"** ]] ; then
    version=`echo $line | grep -ow '[0-9][0-9.]\+[0-9]'`
    # echo $line | sed 's/ //g'
  fi
done < $file_name

if [ -n "$version" ] ; then
  echo $version
else
  echo "No matching version string $var_name in $file_name" >&2
  cd - >/dev/null
  exit 1
fi

cd - >/dev/null || exit 1
