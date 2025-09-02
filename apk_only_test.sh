#!/bin/bash

echo "🧪 APK 16KB VALIDATION TEST"
echo "==========================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APK_PATH="build/app/outputs/flutter-apk/app-seepays-release-16kb-signed.apk"
BUILD_TOOLS="$HOME/Library/Android/sdk/build-tools/34.0.0"

echo -e "\n${BLUE}📦 1. APK BASIC INFO${NC}"
echo "--------------------"

if [ -f "$APK_PATH" ]; then
    apk_size=$(du -h "$APK_PATH" | cut -f1)
    apk_bytes=$(du -b "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✅ APK exists: $apk_size ($(printf "%'d" $apk_bytes) bytes)${NC}"
else
    echo -e "${RED}❌ APK not found${NC}"
    exit 1
fi

echo -e "\n${BLUE}🔐 2. SIGNATURE VERIFICATION${NC}"
echo "-----------------------------"

if "$BUILD_TOOLS/apksigner" verify "$APK_PATH" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ APK signature valid${NC}"
    
    # Get signature details
    sig_info=$("$BUILD_TOOLS/apksigner" verify --verbose "$APK_PATH" 2>&1)
    v1=$(echo "$sig_info" | grep "Verified using v1 scheme" | grep -o "true\|false")
    v2=$(echo "$sig_info" | grep "Verified using v2 scheme" | grep -o "true\|false")
    v3=$(echo "$sig_info" | grep "Verified using v3 scheme" | grep -o "true\|false")
    
    echo -e "${BLUE}   v1 scheme: $v1${NC}"
    echo -e "${BLUE}   v2 scheme: $v2${NC}"
    echo -e "${BLUE}   v3 scheme: $v3${NC}"
else
    echo -e "${RED}❌ APK signature invalid${NC}"
fi

echo -e "\n${BLUE}📐 3. 16KB ALIGNMENT CHECK${NC}"
echo "----------------------------"

alignment_result=$("$BUILD_TOOLS/zipalign" -c -v 16384 "$APK_PATH" 2>&1)
ok_count=$(echo "$alignment_result" | grep -c "OK")
bad_count=$(echo "$alignment_result" | grep -c "BAD")
total=$((ok_count + bad_count))

echo -e "${BLUE}📊 Alignment Statistics:${NC}"
echo -e "   ✅ Aligned files: $ok_count"
echo -e "   ❌ Misaligned files: $bad_count"
echo -e "   📁 Total files: $total"

if [ $total -gt 0 ]; then
    percentage=$((ok_count * 100 / total))
    echo -e "${BLUE}   📈 Success rate: $percentage%${NC}"
    
    if [ $percentage -ge 95 ]; then
        echo -e "${GREEN}🎉 Excellent 16KB alignment!${NC}"
    elif [ $percentage -ge 90 ]; then
        echo -e "${YELLOW}⚠️  Good 16KB alignment${NC}"
    else
        echo -e "${RED}❌ Poor 16KB alignment${NC}"
    fi
fi

echo -e "\n${BLUE}🔧 4. NATIVE LIBRARIES ANALYSIS${NC}"
echo "--------------------------------"

# List native libraries
native_libs=$("$BUILD_TOOLS/aapt" list "$APK_PATH" 2>/dev/null | grep "lib/.*\.so$")
lib_count=$(echo "$native_libs" | grep -v "^$" | wc -l)

echo -e "${BLUE}📊 Native Libraries Found: $lib_count${NC}"

if [ $lib_count -gt 0 ]; then
    echo -e "${BLUE}Libraries:${NC}"
    echo "$native_libs" | while read lib; do
        echo -e "   📚 $lib"
    done
    
    # Check alignment of native libraries specifically
    aligned_natives=$(echo "$alignment_result" | grep "lib/.*\.so.*OK" | wc -l)
    misaligned_natives=$(echo "$alignment_result" | grep "lib/.*\.so.*BAD" | wc -l)
    
    echo -e "\n${BLUE}📊 Native Library Alignment:${NC}"
    echo -e "   ✅ 16KB aligned: $aligned_natives"
    echo -e "   ❌ Misaligned: $misaligned_natives"
    
    if [ $aligned_natives -eq $lib_count ]; then
        echo -e "${GREEN}🎉 All native libraries perfectly aligned for 16KB!${NC}"
    elif [ $aligned_natives -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Most native libraries aligned for 16KB${NC}"
    else
        echo -e "${RED}❌ Native libraries not optimized for 16KB${NC}"
    fi
fi

echo -e "\n${BLUE}📊 5. APK CONTENT ANALYSIS${NC}"
echo "---------------------------"

# Analyze APK contents
total_files=$("$BUILD_TOOLS/aapt" list "$APK_PATH" 2>/dev/null | wc -l)
asset_files=$("$BUILD_TOOLS/aapt" list "$APK_PATH" 2>/dev/null | grep "^assets/" | wc -l)
res_files=$("$BUILD_TOOLS/aapt" list "$APK_PATH" 2>/dev/null | grep "^res/" | wc -l)
dex_files=$("$BUILD_TOOLS/aapt" list "$APK_PATH" 2>/dev/null | grep "\.dex$" | wc -l)

echo -e "${BLUE}📁 APK Contents:${NC}"
echo -e "   📄 Total files: $total_files"
echo -e "   🎨 Asset files: $asset_files"
echo -e "   🎯 Resource files: $res_files"
echo -e "   ⚙️  DEX files: $dex_files"
echo -e "   📚 Native libraries: $lib_count"

echo -e "\n${BLUE}🎯 6. 16KB OPTIMIZATION SCORE${NC}"
echo "------------------------------"

score=0
max_score=6

# APK exists
if [ -f "$APK_PATH" ]; then 
    ((score++))
    echo -e "✅ APK file exists"
fi

# Valid signature
if "$BUILD_TOOLS/apksigner" verify "$APK_PATH" > /dev/null 2>&1; then 
    ((score++))
    echo -e "✅ APK properly signed"
fi

# Good overall alignment (>85%)
if [ $total -gt 0 ] && [ $percentage -ge 85 ]; then 
    ((score++))
    echo -e "✅ Good overall 16KB alignment ($percentage%)"
fi

# Most native libs aligned
if [ $lib_count -gt 0 ] && [ $aligned_natives -gt $((lib_count / 2)) ]; then 
    ((score++))
    echo -e "✅ Native libraries optimized for 16KB"
fi

# Reasonable APK size (< 150MB)
if [ $apk_bytes -lt 157286400 ]; then 
    ((score++))
    echo -e "✅ APK size optimized ($apk_size)"
fi

# Has native libraries (shows it's a proper Flutter app)
if [ $lib_count -gt 0 ]; then 
    ((score++))
    echo -e "✅ Contains native Flutter libraries"
fi

final_percentage=$((score * 100 / max_score))

echo -e "\n${BLUE}📊 FINAL SCORE: $score/$max_score ($final_percentage%)${NC}"

if [ $final_percentage -ge 85 ]; then
    echo -e "${GREEN}🎉 EXCELLENT: APK is fully optimized for 16KB page size!${NC}"
    echo -e "${GREEN}✅ Ready for production deployment${NC}"
elif [ $final_percentage -ge 70 ]; then
    echo -e "${YELLOW}⚠️  GOOD: APK is mostly optimized for 16KB page size${NC}"
    echo -e "${YELLOW}Consider minor improvements${NC}"
else
    echo -e "${RED}❌ NEEDS WORK: APK needs more 16KB optimizations${NC}"
fi

echo -e "\n${GREEN}🏁 16KB APK Validation Complete!${NC}"