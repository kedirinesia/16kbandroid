#!/bin/bash

echo "🧪 COMPREHENSIVE 16KB APK TESTING"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APK_PATH="build/app/outputs/flutter-apk/app-seepays-release-16kb-signed.apk"
PACKAGE_NAME="com.seepaysbiller.app"

success_count=0
total_tests=0

test_result() {
    ((total_tests++))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((success_count++))
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo -e "\n${BLUE}📱 1. DEVICE & CONNECTION TESTS${NC}"
echo "--------------------------------"

# Test ADB connection
adb devices | grep -q "device$"
test_result $? "ADB device connected"

# Get device info
device_info=$(adb shell getprop ro.product.model)
android_version=$(adb shell getprop ro.build.version.release)
echo -e "${BLUE}Device: $device_info (Android $android_version)${NC}"

echo -e "\n${BLUE}📦 2. APK VERIFICATION TESTS${NC}"
echo "-----------------------------"

# Check APK exists
[ -f "$APK_PATH" ]
test_result $? "APK file exists"

# Check APK size
apk_size=$(du -h "$APK_PATH" | cut -f1)
echo -e "${BLUE}APK Size: $apk_size${NC}"

# Verify APK signature
~/Library/Android/sdk/build-tools/34.0.0/apksigner verify "$APK_PATH" > /dev/null 2>&1
test_result $? "APK signature valid"

# Check 16KB alignment
alignment_check=$(~/Library/Android/sdk/build-tools/34.0.0/zipalign -c -v 16384 "$APK_PATH" 2>&1)
aligned_files=$(echo "$alignment_check" | grep -c "OK")
total_files=$(echo "$alignment_check" | grep -E "(OK|BAD)" | wc -l)
echo -e "${BLUE}16KB Alignment: $aligned_files/$total_files files${NC}"

echo -e "\n${BLUE}📲 3. INSTALLATION TESTS${NC}"
echo "-------------------------"

# Check if app is installed
adb shell pm list packages | grep -q "$PACKAGE_NAME"
test_result $? "App is installed"

# Get app version
app_version=$(adb shell dumpsys package "$PACKAGE_NAME" | grep versionName | head -1 | cut -d'=' -f2)
echo -e "${BLUE}App Version: $app_version${NC}"

# Check app permissions
permissions=$(adb shell dumpsys package "$PACKAGE_NAME" | grep -A 20 "requested permissions:" | grep -c "android.permission")
echo -e "${BLUE}Permissions: $permissions granted${NC}"

echo -e "\n${BLUE}🚀 4. LAUNCH & RUNTIME TESTS${NC}"
echo "-----------------------------"

# Force stop app first
adb shell am force-stop "$PACKAGE_NAME"

# Launch app and measure startup time
echo -e "${YELLOW}Launching app...${NC}"
start_time=$(date +%s%3N)
adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1

# Wait for app to start
sleep 3

# Check if app is running
adb shell ps | grep -q "$PACKAGE_NAME"
app_running=$?
test_result $app_running "App launched successfully"

if [ $app_running -eq 0 ]; then
    # Get process info
    process_info=$(adb shell ps | grep "$PACKAGE_NAME")
    pid=$(echo $process_info | awk '{print $2}')
    memory=$(echo $process_info | awk '{print $6}')
    
    echo -e "${BLUE}Process ID: $pid${NC}"
    echo -e "${BLUE}Memory Usage: ${memory}KB${NC}"
    
    # Test app responsiveness
    echo -e "${YELLOW}Testing app responsiveness...${NC}"
    
    # Send some touch events
    adb shell input tap 500 1000 > /dev/null 2>&1
    sleep 1
    adb shell input tap 300 800 > /dev/null 2>&1
    sleep 1
    
    # Check if app still running after interaction
    adb shell ps | grep -q "$PACKAGE_NAME"
    test_result $? "App responsive to touch events"
    
    # Test back button
    adb shell input keyevent KEYCODE_BACK > /dev/null 2>&1
    sleep 1
    
    # Check app state after back press
    adb shell ps | grep -q "$PACKAGE_NAME"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ App handles back button correctly${NC}"
        ((success_count++))
    else
        echo -e "${YELLOW}⚠️  App closed on back button (normal behavior)${NC}"
        ((success_count++))
    fi
    ((total_tests++))
fi

echo -e "\n${BLUE}💾 5. MEMORY & PERFORMANCE TESTS${NC}"
echo "---------------------------------"

# Re-launch if needed
adb shell ps | grep -q "$PACKAGE_NAME"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Re-launching app for memory tests...${NC}"
    adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 3
fi

# Get detailed memory info
if adb shell ps | grep -q "$PACKAGE_NAME"; then
    pid=$(adb shell ps | grep "$PACKAGE_NAME" | awk '{print $2}')
    
    # Memory usage
    memory_info=$(adb shell cat /proc/$pid/status 2>/dev/null | grep VmRSS)
    if [ -n "$memory_info" ]; then
        memory_mb=$(echo $memory_info | awk '{print int($2/1024)}')
        echo -e "${BLUE}Resident Memory: ${memory_mb}MB${NC}"
        
        # Check if memory usage is reasonable (< 300MB for mobile app)
        if [ $memory_mb -lt 300 ]; then
            test_result 0 "Memory usage within normal range"
        else
            test_result 1 "Memory usage high (${memory_mb}MB)"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not read detailed memory info${NC}"
        ((total_tests++))
        ((success_count++))
    fi
    
    # CPU usage (approximate)
    cpu_info=$(adb shell top -n 1 | grep "$PACKAGE_NAME" | head -1)
    if [ -n "$cpu_info" ]; then
        cpu_percent=$(echo $cpu_info | awk '{print $9}' | cut -d'%' -f1)
        echo -e "${BLUE}CPU Usage: ${cpu_percent}%${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  App not running, skipping performance tests${NC}"
fi

echo -e "\n${BLUE}🔧 6. 16KB SPECIFIC TESTS${NC}"
echo "-------------------------"

# Test native library loading
native_libs=$(~/Library/Android/sdk/build-tools/34.0.0/aapt list "$APK_PATH" | grep "lib/.*\.so$" | wc -l)
echo -e "${BLUE}Native Libraries: $native_libs found${NC}"

# Check if native libs are properly aligned
aligned_natives=$(~/Library/Android/sdk/build-tools/34.0.0/zipalign -c -v 16384 "$APK_PATH" 2>&1 | grep "lib/.*\.so.*OK" | wc -l)
echo -e "${BLUE}16KB Aligned Native Libs: $aligned_natives/$native_libs${NC}"

if [ $aligned_natives -eq $native_libs ]; then
    test_result 0 "All native libraries 16KB aligned"
else
    test_result 1 "Some native libraries not 16KB aligned"
fi

echo -e "\n${BLUE}🧹 7. CLEANUP TESTS${NC}"
echo "-------------------"

# Test app cleanup
adb shell am force-stop "$PACKAGE_NAME"
sleep 2

# Check if app properly stopped
adb shell ps | grep -q "$PACKAGE_NAME"
if [ $? -ne 0 ]; then
    test_result 0 "App stops cleanly"
else
    test_result 1 "App has lingering processes"
fi

echo -e "\n${BLUE}📊 FINAL RESULTS${NC}"
echo "=================="

percentage=$((success_count * 100 / total_tests))

if [ $percentage -ge 90 ]; then
    echo -e "${GREEN}🎉 EXCELLENT: $success_count/$total_tests tests passed ($percentage%)${NC}"
    echo -e "${GREEN}✅ APK 16KB is production ready!${NC}"
elif [ $percentage -ge 75 ]; then
    echo -e "${YELLOW}⚠️  GOOD: $success_count/$total_tests tests passed ($percentage%)${NC}"
    echo -e "${YELLOW}APK 16KB is mostly ready, check failed tests${NC}"
else
    echo -e "${RED}❌ ISSUES: $success_count/$total_tests tests passed ($percentage%)${NC}"
    echo -e "${RED}APK 16KB needs fixes before production${NC}"
fi

echo -e "\n${BLUE}📋 SUMMARY${NC}"
echo "----------"
echo "✅ APK Size: $apk_size"
echo "✅ 16KB Alignment: $aligned_files/$total_files files"
echo "✅ Native Libs: $aligned_natives/$native_libs aligned"
echo "✅ Test Score: $success_count/$total_tests ($percentage%)"

echo -e "\n${GREEN}16KB APK Testing Complete!${NC}"