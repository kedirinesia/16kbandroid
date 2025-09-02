#!/bin/bash

echo "🧪 SIMPLE 16KB APK TEST"
echo "======================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APK_PATH="build/app/outputs/flutter-apk/app-seepays-release-16kb-signed.apk"
PACKAGE_NAME="com.seepaysbiller.app"

echo -e "\n${BLUE}📱 1. BASIC CHECKS${NC}"
echo "-------------------"

# Check device
device=$(adb -s emulator-5556 shell getprop ro.product.model 2>/dev/null)
if [ -n "$device" ]; then
    echo -e "${GREEN}✅ Device: $device${NC}"
else
    echo -e "${RED}❌ No device connected${NC}"
    exit 1
fi

# Check APK
if [ -f "$APK_PATH" ]; then
    apk_size=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✅ APK exists: $apk_size${NC}"
else
    echo -e "${RED}❌ APK not found${NC}"
    exit 1
fi

# Check installation
if adb -s emulator-5556 shell pm list packages 2>/dev/null | grep -q "$PACKAGE_NAME"; then
    echo -e "${GREEN}✅ App installed${NC}"
else
    echo -e "${RED}❌ App not installed${NC}"
    exit 1
fi

echo -e "\n${BLUE}🚀 2. LAUNCH TEST${NC}"
echo "------------------"

# Launch app
echo -e "${YELLOW}Launching app...${NC}"
adb -s emulator-5556 shell am start -n "$PACKAGE_NAME/.MainActivity" 2>/dev/null

# Wait and check
sleep 3

if adb -s emulator-5556 shell ps 2>/dev/null | grep -q "$PACKAGE_NAME"; then
    pid=$(adb -s emulator-5556 shell ps 2>/dev/null | grep "$PACKAGE_NAME" | awk '{print $2}')
    echo -e "${GREEN}✅ App running (PID: $pid)${NC}"
    
    # Get memory usage
    memory=$(adb -s emulator-5556 shell ps 2>/dev/null | grep "$PACKAGE_NAME" | awk '{print $6}')
    if [ -n "$memory" ]; then
        memory_mb=$((memory / 1024))
        echo -e "${BLUE}📊 Memory: ${memory_mb}MB${NC}"
    fi
else
    echo -e "${RED}❌ App not running${NC}"
fi

echo -e "\n${BLUE}🔧 3. 16KB ALIGNMENT CHECK${NC}"
echo "----------------------------"

# Check alignment
alignment_result=$(~/Library/Android/sdk/build-tools/34.0.0/zipalign -c -v 16384 "$APK_PATH" 2>&1)
ok_count=$(echo "$alignment_result" | grep -c "OK")
bad_count=$(echo "$alignment_result" | grep -c "BAD")
total=$((ok_count + bad_count))

echo -e "${BLUE}📊 Alignment Results:${NC}"
echo -e "   OK files: $ok_count"
echo -e "   BAD files: $bad_count"
echo -e "   Total: $total"

percentage=$((ok_count * 100 / total))
if [ $percentage -ge 95 ]; then
    echo -e "${GREEN}✅ Excellent alignment: $percentage%${NC}"
elif [ $percentage -ge 90 ]; then
    echo -e "${YELLOW}⚠️  Good alignment: $percentage%${NC}"
else
    echo -e "${RED}❌ Poor alignment: $percentage%${NC}"
fi

echo -e "\n${BLUE}📦 4. NATIVE LIBRARIES CHECK${NC}"
echo "-----------------------------"

# Check native libraries
native_libs=$(~/Library/Android/sdk/build-tools/34.0.0/aapt list "$APK_PATH" 2>/dev/null | grep "lib/.*\.so$")
lib_count=$(echo "$native_libs" | wc -l)

echo -e "${BLUE}📊 Native Libraries: $lib_count found${NC}"

# Check which ones are aligned
aligned_libs=$(echo "$alignment_result" | grep "lib/.*\.so.*OK" | wc -l)
echo -e "${BLUE}📊 16KB Aligned: $aligned_libs/$lib_count${NC}"

if [ $aligned_libs -eq $lib_count ]; then
    echo -e "${GREEN}✅ All native libraries aligned${NC}"
else
    echo -e "${YELLOW}⚠️  Some libraries not perfectly aligned${NC}"
fi

echo -e "\n${BLUE}🎯 5. FINAL SCORE${NC}"
echo "------------------"

score=0
max_score=5

# APK exists and reasonable size
if [ -f "$APK_PATH" ]; then ((score++)); fi

# App installed
if adb -s emulator-5556 shell pm list packages 2>/dev/null | grep -q "$PACKAGE_NAME"; then ((score++)); fi

# App can launch
if adb -s emulator-5556 shell ps 2>/dev/null | grep -q "$PACKAGE_NAME"; then ((score++)); fi

# Good alignment (>90%)
if [ $percentage -ge 90 ]; then ((score++)); fi

# Most native libs aligned
if [ $aligned_libs -gt 0 ]; then ((score++)); fi

final_percentage=$((score * 100 / max_score))

echo -e "${BLUE}📊 Test Score: $score/$max_score ($final_percentage%)${NC}"

if [ $final_percentage -ge 80 ]; then
    echo -e "${GREEN}🎉 APK 16KB: PRODUCTION READY!${NC}"
elif [ $final_percentage -ge 60 ]; then
    echo -e "${YELLOW}⚠️  APK 16KB: MOSTLY READY${NC}"
else
    echo -e "${RED}❌ APK 16KB: NEEDS WORK${NC}"
fi

echo -e "\n${GREEN}✅ Testing Complete!${NC}"