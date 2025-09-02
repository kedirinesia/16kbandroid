#!/bin/bash

# Script untuk mengecek dukungan 16KB pada emulator dan APK
# Usage: ./check_16kb_support.sh [applicationId]

APP_ID=${1:-"mobile.payuni.id"}  # Default payuniovo
DEVICE=$(adb devices | grep -E "emulator-[0-9]+" | head -1 | awk '{print $1}')

echo "🔍 CHECKING 16KB SUPPORT FOR: $APP_ID"
echo "📱 TARGET DEVICE: $DEVICE"
echo "=" | tr '=' '='| head -c 60; echo

# 1. Check emulator page size
echo "1️⃣  EMULATOR PAGE SIZE CHECK:"
PAGE_SIZE=$(adb -s $DEVICE shell getprop ro.product.cpu.pagesize.max 2>/dev/null)
if [ -n "$PAGE_SIZE" ]; then
    if [ "$PAGE_SIZE" -ge 16384 ]; then
        echo "✅ Emulator supports 16KB page size: $PAGE_SIZE bytes"
    else
        echo "❌ Emulator only supports: $PAGE_SIZE bytes (need ≥16384)"
    fi
else
    echo "⚠️  Could not detect page size"
fi
echo

# 2. Check if app is installed
echo "2️⃣  APP INSTALLATION CHECK:"
INSTALLED=$(adb -s $DEVICE shell pm list packages | grep "$APP_ID")
if [ -n "$INSTALLED" ]; then
    echo "✅ App is installed: $INSTALLED"
else
    echo "❌ App not installed. Please install first."
    exit 1
fi
echo

# 3. Check app info
echo "3️⃣  APP PACKAGE INFO:"
adb -s $DEVICE shell dumpsys package "$APP_ID" | grep -E "versionName|versionCode|targetSdk|minSdk" | head -4
echo

# 4. Check APK path and try to analyze
echo "4️⃣  APK ANALYSIS:"
APK_PATH=$(adb -s $DEVICE shell pm path "$APP_ID" | head -1 | cut -d':' -f2)
if [ -n "$APK_PATH" ]; then
    echo "📦 APK Location: $APK_PATH"
    
    # Try to get file info
    echo "📏 APK Size:"
    adb -s $DEVICE shell ls -lh "$APK_PATH" | awk '{print $5 " " $8}'
    
    # Try to check alignment (may need root)
    echo "🔧 Checking alignment..."
    adb -s $DEVICE shell "which zipalign" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   zipalign tool found, checking alignment..."
        adb -s $DEVICE shell zipalign -c -v 16384 "$APK_PATH" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ APK is aligned for 16KB"
        else
            echo "❌ APK is not properly aligned for 16KB"
        fi
    else
        echo "   zipalign not available on device"
    fi
else
    echo "❌ Could not find APK path"
fi
echo

# 5. Check native libraries
echo "5️⃣  NATIVE LIBRARIES CHECK:"
echo "🔍 Checking for supported architectures..."
ARCHS=$(adb -s $DEVICE shell dumpsys package "$APP_ID" | grep -o "arm64-v8a\|armeabi-v7a\|x86_64" | sort -u)
if [ -n "$ARCHS" ]; then
    echo "✅ Supported architectures:"
    echo "$ARCHS" | sed 's/^/   - /'
else
    echo "⚠️  Could not detect native architectures"
fi
echo

# 6. Runtime check
echo "6️⃣  RUNTIME CHECK:"
echo "🚀 Launching app to test..."
adb -s $DEVICE shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 3

# Check if app is running
RUNNING=$(adb -s $DEVICE shell ps | grep "$APP_ID" | wc -l)
if [ "$RUNNING" -gt 0 ]; then
    echo "✅ App launched successfully"
    echo "📊 Memory info:"
    adb -s $DEVICE shell dumpsys meminfo "$APP_ID" | grep -E "TOTAL|Native Heap|Graphics" | head -3
else
    echo "❌ App failed to launch or crashed"
fi
echo

# 7. Final verdict
echo "🏁 FINAL VERDICT:"
echo "=" | tr '=' '='| head -c 60; echo
if [ "$PAGE_SIZE" -ge 16384 ] && [ -n "$INSTALLED" ] && [ "$RUNNING" -gt 0 ]; then
    echo "🎉 SUCCESS: App appears to be compatible with 16KB page size!"
    echo "✅ Emulator supports 16KB: YES"
    echo "✅ App installed: YES"  
    echo "✅ App runs: YES"
else
    echo "⚠️  ISSUES DETECTED:"
    [ "$PAGE_SIZE" -lt 16384 ] && echo "   - Emulator page size too small"
    [ -z "$INSTALLED" ] && echo "   - App not installed"
    [ "$RUNNING" -eq 0 ] && echo "   - App failed to run"
fi
echo "=" | tr '=' '='| head -c 60; echo