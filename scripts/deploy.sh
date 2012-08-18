#!/bin/sh

node_modules/.bin/cake build
mkdir ../porcupine/node_modules/spine -p
cp -r lib ../porcupine/node_modules/spine/lib
cp -r src ../porcupine/node_modules/spine/src
