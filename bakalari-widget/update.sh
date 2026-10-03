#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

echo "Updating Bakaláři widget..."

mkdir -p package/contents/data
cp parsed_timetable.json package/contents/data/timetable.json
cp parsed_timetable.js package/contents/data/timetable.js

kpackagetool6 \
    --type Plasma/Applet \
    --remove cz.saruman.bakalari \
    2>/dev/null || true

kpackagetool6 \
    --type Plasma/Applet \
    --install package

echo "Restarting Plasma..."

systemctl --user restart plasma-plasmashell.service

echo "Done."
