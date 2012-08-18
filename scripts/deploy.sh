#!/bin/sh

node_modules/.bin/cake build
rsync . ../porcupine/node_modules/spine -r
