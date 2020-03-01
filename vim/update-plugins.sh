#!/bin/sh

pushd ~/.vim/bundle
for d in */ ; do
  pushd $d && git pull && popd
done
popd
