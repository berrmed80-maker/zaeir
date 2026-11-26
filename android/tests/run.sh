#!/bin/bash
# runs inside the emulator action; test copy is b/test.apk
mkdir -p shots-android
adb install -r b/test.apk || { echo INSTALL_FAILED; exit 1; }
adb logcat -c
python3 android/tests/drive.py
rc=$?
adb logcat -d > shots-android/logcat.txt
grep -c "FATAL EXCEPTION" shots-android/logcat.txt && { grep -A12 "FATAL EXCEPTION" shots-android/logcat.txt | head -40; exit 1; }
exit $rc
