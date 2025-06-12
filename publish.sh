#!/bin/bash

PACKAGES=("riverpod2_persist_annotation" "riverpod2_persist_generator" "riverpod2_persist_storage" "riverpod2_persist")

for pkg in "${PACKAGES[@]}"
do
  echo "Publishing $pkg..."
  cd packages/$pkg
  fvm flutter pub publish --dry-run --server=https://pub.dev || exit 1
  fvm flutter pub publish --server=https://pub.dev || exit 1
  cd ../..
done
