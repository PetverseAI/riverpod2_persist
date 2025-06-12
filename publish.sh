#!/bin/bash

PACKAGES=("riverpod2_persist_annotation" "riverpod2_persist_generator" "riverpod2_persist_storage" "riverpod2_persist")

for pkg in "${PACKAGES[@]}"
do
  echo "Publishing $pkg..."
  export PUB_HOSTED_URL=https://pub.dev
  cd packages/$pkg
  # fvm flutter pub publish --dry-run || exit 1
  flutter pub publish || exit 1
  cd ../..
done
