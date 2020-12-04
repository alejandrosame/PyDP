#!/bin/bash

## Set variables

# Get platform value for bazel
# Bazel expects as config values: linux, arm, osx, windows, etc
PLATFORM=$RUNNER_OS

if [ -z "$PLATFORM" ]; then
    PLATFORM=$OSTYPE
fi

# Make value lowercase
PLATFORM=$(echo "$PLATFORM" | tr '[:upper:]' '[:lower:]')

case $PLATFORM in
  *"linux"*)
    PLATFORM="Linux"
    ;;
  *"macos"* | *"darwin"*)
    PLATFORM="macOS"
    ;;
esac

# Search specific python bin and lib folders to compile against the poetry env
PYTHONHOME=$(poetry run which python)
PYTHONPATH=$(poetry run python -c 'import sys; print([x for x in sys.path if "site-packages" in x][0]);')

# Give user feedback
echo -e "Running bazel with:\n\tPLATFORM=$PLATFORM\n\tPYTHONHOME=$PYTHONHOME"

# Setup poetry env
poetry install

# Compile code
bazel coverage src/python:bindings_test \
  --config $PLATFORM \
  --verbose_failures \
  --action_env=PYTHON_BIN_PATH=$PYTHONHOME \
  --action_env=PYTHON_LIB_PATH=$PYTHONPATH

# Delete the previously compiled package and copy the new one
rm -f ./src/pydp/_pydp.so
cp -f ./bazel-bin/src/bindings/_pydp.so ./src/pydp
