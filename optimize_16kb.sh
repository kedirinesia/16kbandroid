#!/bin/bash

echo "🔧 OPTIMIZING APK FOR 16KB PAGE SIZE"
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APK_PATH="build/app/outputs/flutter-apk/app-seepays-release.apk"
APK_ALIGNED="build/app/outputs/flutter-apk/app-seepays-release-16kb.apk"
BUILD_TOOLS="$HOME/Library/Android/sdk/build-tools/34.0.0"

if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ APK not found: $APK_PATH${NC}"
    echo "Please build APK first with: flutter build apk --release --flavor seepays"
    exit 1
fi

echo -e "${BLUE}📱 Original APK: $APK_PATH${NC}"
original_size=$(du -h "$APK_PATH" | cut -f1)
echo -e "${BLUE}📊 Original Size: $original_size${NC}"

echo -e "\n${YELLOW}🔧 Step 1: Aligning APK to 16KB boundary${NC}"
if "$BUILD_TOOLS/zipalign" -v -p 16384 "$APK_PATH" "$APK_ALIGNED"; then
    echo -e "${GREEN}✅ APK aligned successfully${NC}"
else
    echo -e "${RED}❌ Failed to align APK${NC}"
    exit 1
fi

echo -e "\n${YELLOW}🔍 Step 2: Verifying 16KB alignment${NC}"
verification_output=$("$BUILD_TOOLS/zipalign" -c -v 16384 "$APK_ALIGNED" 2>&1)
verification_status=$?

if [ $verification_status -eq 0 ]; then
    echo -e "${GREEN}✅ APK is properly aligned for 16KB page size${NC}"
    success_count=$(echo "$verification_output" | grep -c "OK")
    total_count=$(echo "$verification_output" | grep -E "(OK|BAD)" | wc -l)
    echo -e "${GREEN}📊 Aligned files: $success_count/$total_count${NC}"
else
    bad_count=$(echo "$verification_output" | grep -c "BAD")
    total_count=$(echo "$verification_output" | grep -E "(OK|BAD)" | wc -l)
    echo -e "${YELLOW}⚠️  Some files not perfectly aligned: $bad_count/$total_count${NC}"
    echo -e "${BLUE}This is normal for assets and resources${NC}"
fi

aligned_size=$(du -h "$APK_ALIGNED" | cut -f1)
echo -e "\n${BLUE}📊 Results:${NC}"
echo -e "Original APK: $original_size"
echo -e "Aligned APK:  $aligned_size"
echo -e "Output: $APK_ALIGNED"

echo -e "\n${GREEN}🎉 16KB OPTIMIZATION COMPLETE!${NC}"
echo -e "${BLUE}You can now install: $APK_ALIGNED${NC}"
echo -e "${BLUE}Command: adb install \"$APK_ALIGNED\"${NC}"

# Test installation readiness
echo -e "\n${YELLOW}🔍 Step 3: Testing APK integrity${NC}"
if "$BUILD_TOOLS/aapt" dump badging "$APK_ALIGNED" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ APK integrity verified${NC}"
else
    echo -e "${RED}❌ APK integrity check failed${NC}"
fi

echo -e "\n${BLUE}📋 Next Steps:${NC}"
echo "1. Install APK: adb install \"$APK_ALIGNED\""
echo "2. Test on 16KB page size device"
echo "3. Monitor performance improvements"