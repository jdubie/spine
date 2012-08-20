#!/bin/sh

node_modules/.bin/cake build
rsync . ../porcupine/node_modules/spine -r
cp -r lib ../porcupine/vendor/scripts/spine
mv ../porcupine/vendor/scripts/spine/lib/spine.js ../porcupine/vendor/scripts/spine/spine.js
