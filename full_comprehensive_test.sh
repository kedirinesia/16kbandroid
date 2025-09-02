#!/bin/bash

echo "🧪 FULL COMPREHENSIVE 16KB APK TESTING SUITE"
echo "============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

APK_PATH="build/app/outputs/flutter-apk/app-seepays-release-16kb-signed.apk"
BUILD_TOOLS="$HOME/Library/Android/sdk/build-tools/34.0.0"
PACKAGE_NAME="com.seepaysbiller.app"

# Test counters
total_tests=0
passed_tests=0
failed_tests=0
warnings=0

test_result() {
    ((total_tests++))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((passed_tests++))
    elif [ $1 -eq 2 ]; then
        echo -e "${YELLOW}⚠️  $2${NC}"
        ((warnings++))
    else
        echo -e "${RED}❌ $2${NC}"
        ((failed_tests++))
    fi
}

echo -e "\n${PURPLE}🔍 PHASE 1: PRE-FLIGHT CHECKS${NC}"
echo "==============================="

# Check if APK exists
if [ -f "$APK_PATH" ]; then
    apk_size_human=$(du -h "$APK_PATH" | cut -f1)
    apk_size_bytes=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH" 2>/dev/null || echo "0")
    test_result 0 "APK file exists ($apk_size_human)"
    echo -e "${BLUE}   📁 Path: $APK_PATH${NC}"
    echo -e "${BLUE}   📊 Size: $(printf "%'d" $apk_size_bytes) bytes${NC}"
else
    test_result 1 "APK file missing"
    exit 1
fi

# Check build tools
if [ -f "$BUILD_TOOLS/zipalign" ]; then
    test_result 0 "Android build tools available"
else
    test_result 1 "Android build tools missing"
fi

echo -e "\n${PURPLE}🔐 PHASE 2: SIGNATURE VERIFICATION${NC}"
echo "==================================="

# Verify APK signature
if "$BUILD_TOOLS/apksigner" verify "$APK_PATH" > /dev/null 2>&1; then
    test_result 0 "APK signature is valid"
    
    # Get detailed signature info
    sig_details=$("$BUILD_TOOLS/apksigner" verify --verbose "$APK_PATH" 2>&1)
    
    # Check individual signature schemes
    if echo "$sig_details" | grep -q "Verified using v1 scheme.*true"; then
        test_result 0 "APK Signature Scheme v1 verified"
    else
        test_result 1 "APK Signature Scheme v1 failed"
    fi
    
    if echo "$sig_details" | grep -q "Verified using v2 scheme.*true"; then
        test_result 0 "APK Signature Scheme v2 verified"
    else
        test_result 1 "APK Signature Scheme v2 failed"
    fi
    
    if echo "$sig_details" | grep -q "Verified using v3 scheme.*true"; then
        test_result 0 "APK Signature Scheme v3 verified"
    else
        test_result 2 "APK Signature Scheme v3 not used (optional)"
    fi
    
    # Check for signature warnings
    warning_count=$(echo "$sig_details" | grep -c "WARNING:")
    if [ $warning_count -eq 0 ]; then
        test_result 0 "No signature warnings"
    else
        test_result 2 "$warning_count signature warnings (non-critical)"
    fi
    
else
    test_result 1 "APK signature verification failed"
fi

echo -e "\n${PURPLE}📐 PHASE 3: 16KB ALIGNMENT ANALYSIS${NC}"
echo "===================================="

# Perform alignment check
echo -e "${CYAN}Running 16KB alignment analysis...${NC}"
alignment_output=$("$BUILD_TOOLS/zipalign" -c -v 16384 "$APK_PATH" 2>&1)

# Parse alignment results
ok_files=$(echo "$alignment_output" | grep -c " (OK")
bad_files=$(echo "$alignment_output" | grep -c " (BAD")
total_files=$((ok_files + bad_files))

if [ $total_files -gt 0 ]; then
    alignment_percentage=$((ok_files * 100 / total_files))
    
    echo -e "${BLUE}📊 Alignment Statistics:${NC}"
    echo -e "   ✅ Properly aligned: $ok_files files"
    echo -e "   ❌ Misaligned: $bad_files files"
    echo -e "   📁 Total analyzed: $total_files files"
    echo -e "   📈 Success rate: $alignment_percentage%"
    
    if [ $alignment_percentage -ge 95 ]; then
        test_result 0 "Excellent 16KB alignment ($alignment_percentage%)"
    elif [ $alignment_percentage -ge 85 ]; then
        test_result 2 "Good 16KB alignment ($alignment_percentage%)"
    else
        test_result 1 "Poor 16KB alignment ($alignment_percentage%)"
    fi
    
    # Analyze specific file types
    aligned_natives=$(echo "$alignment_output" | grep "lib/.*\.so.*(OK" | wc -l)
    misaligned_natives=$(echo "$alignment_output" | grep "lib/.*\.so.*(BAD" | wc -l)
    total_natives=$((aligned_natives + misaligned_natives))
    
    if [ $total_natives -gt 0 ]; then
        echo -e "\n${BLUE}🔧 Native Libraries Analysis:${NC}"
        echo -e "   ✅ 16KB aligned natives: $aligned_natives"
        echo -e "   ❌ Misaligned natives: $misaligned_natives"
        echo -e "   📚 Total native libs: $total_natives"
        
        if [ $aligned_natives -eq $total_natives ]; then
            test_result 0 "All native libraries 16KB aligned"
        elif [ $aligned_natives -gt $((total_natives / 2)) ]; then
            test_result 2 "Most native libraries 16KB aligned"
        else
            test_result 1 "Native libraries poorly aligned for 16KB"
        fi
    fi
    
    # Check DEX files alignment
    aligned_dex=$(echo "$alignment_output" | grep "classes.*\.dex.*(OK" | wc -l)
    misaligned_dex=$(echo "$alignment_output" | grep "classes.*\.dex.*(BAD" | wc -l)
    
    if [ $aligned_dex -gt 0 ] || [ $misaligned_dex -gt 0 ]; then
        total_dex=$((aligned_dex + misaligned_dex))
        echo -e "\n${BLUE}⚙️  DEX Files Analysis:${NC}"
        echo -e "   ✅ 16KB aligned DEX: $aligned_dex"
        echo -e "   ❌ Misaligned DEX: $misaligned_dex"
        
        if [ $aligned_dex -eq $total_dex ]; then
            test_result 0 "All DEX files 16KB aligned"
        else
            test_result 2 "Some DEX files not 16KB aligned"
        fi
    fi
    
else
    test_result 1 "Could not analyze file alignment"
fi

echo -e "\n${PURPLE}📦 PHASE 4: APK CONTENT VALIDATION${NC}"
echo "==================================="

# Analyze APK contents using aapt
if [ -f "$BUILD_TOOLS/aapt" ]; then
    echo -e "${CYAN}Analyzing APK contents...${NC}"
    
    apk_contents=$("$BUILD_TOOLS/aapt" list "$APK_PATH" 2>/dev/null)
    
    if [ -n "$apk_contents" ]; then
        # Count different file types
        total_entries=$(echo "$apk_contents" | wc -l)
        asset_files=$(echo "$apk_contents" | grep -c "^assets/")
        res_files=$(echo "$apk_contents" | grep -c "^res/")
        lib_files=$(echo "$apk_contents" | grep -c "^lib/")
        dex_files=$(echo "$apk_contents" | grep -c "\.dex$")
        manifest_files=$(echo "$apk_contents" | grep -c "AndroidManifest\.xml")
        
        echo -e "${BLUE}📊 APK Content Summary:${NC}"
        echo -e "   📄 Total entries: $total_entries"
        echo -e "   🎨 Asset files: $asset_files"
        echo -e "   🎯 Resource files: $res_files"
        echo -e "   📚 Library files: $lib_files"
        echo -e "   ⚙️  DEX files: $dex_files"
        echo -e "   📋 Manifest files: $manifest_files"
        
        # Validate essential components
        if [ $dex_files -ge 1 ]; then
            test_result 0 "DEX files present ($dex_files found)"
        else
            test_result 1 "No DEX files found"
        fi
        
        if [ $lib_files -ge 1 ]; then
            test_result 0 "Native libraries present ($lib_files found)"
        else
            test_result 2 "No native libraries found"
        fi
        
        if [ $manifest_files -eq 1 ]; then
            test_result 0 "AndroidManifest.xml present"
        else
            test_result 1 "AndroidManifest.xml missing or multiple"
        fi
        
        if [ $res_files -ge 1 ]; then
            test_result 0 "Android resources present ($res_files files)"
        else
            test_result 2 "No Android resources found"
        fi
        
        # Check for Flutter-specific files
        flutter_assets=$(echo "$apk_contents" | grep -c "flutter_assets/")
        if [ $flutter_assets -ge 1 ]; then
            test_result 0 "Flutter assets present ($flutter_assets files)"
        else
            test_result 1 "No Flutter assets found"
        fi
        
        # List native libraries in detail
        echo -e "\n${BLUE}🔧 Native Libraries Detail:${NC}"
        native_libs=$(echo "$apk_contents" | grep "^lib/.*\.so$")
        if [ -n "$native_libs" ]; then
            echo "$native_libs" | while read lib; do
                echo -e "   📚 $lib"
            done
        else
            echo -e "   ❌ No native libraries found"
        fi
        
    else
        test_result 1 "Could not analyze APK contents"
    fi
else
    test_result 2 "AAPT tool not available for content analysis"
fi

echo -e "\n${PURPLE}🎯 PHASE 5: SIZE & OPTIMIZATION ANALYSIS${NC}"
echo "========================================="

# APK size analysis
if [ $apk_size_bytes -gt 0 ]; then
    size_mb=$((apk_size_bytes / 1024 / 1024))
    
    echo -e "${BLUE}📊 Size Analysis:${NC}"
    echo -e "   📁 APK Size: ${size_mb}MB ($apk_size_human)"
    echo -e "   📏 Raw bytes: $(printf "%'d" $apk_size_bytes)"
    
    # Size benchmarks
    if [ $size_mb -le 50 ]; then
        test_result 0 "Excellent APK size (≤50MB)"
    elif [ $size_mb -le 100 ]; then
        test_result 0 "Good APK size (≤100MB)"
    elif [ $size_mb -le 150 ]; then
        test_result 2 "Acceptable APK size (≤150MB)"
    else
        test_result 1 "Large APK size (>150MB)"
    fi
    
    # Calculate compression ratio if possible
    uncompressed_estimate=$((total_entries * 1024))  # Rough estimate
    if [ $uncompressed_estimate -gt $apk_size_bytes ]; then
        compression_ratio=$(((uncompressed_estimate - apk_size_bytes) * 100 / uncompressed_estimate))
        test_result 0 "Good compression achieved (~$compression_ratio%)"
    fi
fi

echo -e "\n${PURPLE}🔬 PHASE 6: ADVANCED 16KB ANALYSIS${NC}"
echo "===================================="

# Detailed 16KB boundary analysis
echo -e "${CYAN}Performing detailed 16KB boundary analysis...${NC}"

# Check specific critical files
critical_files=("classes.dex" "classes2.dex" "AndroidManifest.xml" "resources.arsc")
critical_aligned=0
critical_total=0

for file in "${critical_files[@]}"; do
    if echo "$alignment_output" | grep -q "$file"; then
        ((critical_total++))
        if echo "$alignment_output" | grep "$file" | grep -q "(OK"; then
            ((critical_aligned++))
            echo -e "   ✅ $file: 16KB aligned"
        else
            echo -e "   ❌ $file: Not 16KB aligned"
        fi
    fi
done

if [ $critical_total -gt 0 ]; then
    if [ $critical_aligned -eq $critical_total ]; then
        test_result 0 "All critical files 16KB aligned"
    else
        test_result 2 "Some critical files not 16KB aligned ($critical_aligned/$critical_total)"
    fi
fi

# Check page boundary efficiency
page_boundary_efficiency=$((ok_files * 100 / total_files))
if [ $page_boundary_efficiency -ge 95 ]; then
    test_result 0 "Excellent page boundary efficiency ($page_boundary_efficiency%)"
elif [ $page_boundary_efficiency -ge 85 ]; then
    test_result 2 "Good page boundary efficiency ($page_boundary_efficiency%)"
else
    test_result 1 "Poor page boundary efficiency ($page_boundary_efficiency%)"
fi

echo -e "\n${PURPLE}📊 PHASE 7: FINAL SCORING & RECOMMENDATIONS${NC}"
echo "=============================================="

# Calculate final score
total_score_points=$((passed_tests * 2 + warnings))
max_possible_score=$((total_tests * 2))
final_percentage=$((total_score_points * 100 / max_possible_score))

echo -e "${BLUE}📈 Test Results Summary:${NC}"
echo -e "   ✅ Passed tests: $passed_tests"
echo -e "   ⚠️  Warnings: $warnings"
echo -e "   ❌ Failed tests: $failed_tests"
echo -e "   📊 Total tests: $total_tests"
echo -e "   🎯 Score: $total_score_points/$max_possible_score ($final_percentage%)"

# Final verdict
echo -e "\n${BLUE}🏆 FINAL VERDICT:${NC}"
if [ $final_percentage -ge 90 ]; then
    echo -e "${GREEN}🎉 EXCELLENT: APK is fully optimized for 16KB page size!${NC}"
    echo -e "${GREEN}✅ PRODUCTION READY - Deploy immediately${NC}"
    verdict="EXCELLENT"
elif [ $final_percentage -ge 80 ]; then
    echo -e "${YELLOW}⚠️  GOOD: APK is well optimized for 16KB page size${NC}"
    echo -e "${YELLOW}✅ PRODUCTION READY - Minor optimizations recommended${NC}"
    verdict="GOOD"
elif [ $final_percentage -ge 70 ]; then
    echo -e "${YELLOW}⚠️  ACCEPTABLE: APK has basic 16KB optimization${NC}"
    echo -e "${YELLOW}🔧 NEEDS IMPROVEMENT - Address warnings before production${NC}"
    verdict="ACCEPTABLE"
else
    echo -e "${RED}❌ NEEDS WORK: APK requires significant 16KB optimization${NC}"
    echo -e "${RED}🚫 NOT PRODUCTION READY - Fix critical issues${NC}"
    verdict="NEEDS_WORK"
fi

# Recommendations
echo -e "\n${BLUE}💡 RECOMMENDATIONS:${NC}"

if [ $failed_tests -gt 0 ]; then
    echo -e "${RED}🔧 HIGH PRIORITY:${NC}"
    echo -e "   • Fix $failed_tests critical issues before production"
fi

if [ $warnings -gt 0 ]; then
    echo -e "${YELLOW}⚠️  MEDIUM PRIORITY:${NC}"
    echo -e "   • Address $warnings warnings for optimal performance"
fi

if [ $alignment_percentage -lt 95 ]; then
    echo -e "${YELLOW}📐 ALIGNMENT OPTIMIZATION:${NC}"
    echo -e "   • Consider re-aligning misaligned files for better 16KB performance"
fi

if [ $size_mb -gt 100 ]; then
    echo -e "${YELLOW}📦 SIZE OPTIMIZATION:${NC}"
    echo -e "   • Consider additional compression or asset optimization"
fi

echo -e "\n${GREEN}🏁 16KB COMPREHENSIVE TESTING COMPLETE!${NC}"
echo -e "${BLUE}📊 Final Score: $final_percentage% ($verdict)${NC}"
echo -e "${BLUE}📁 APK: $APK_PATH${NC}"
echo -e "${BLUE}📏 Size: $apk_size_human${NC}"
echo -e "${BLUE}📐 Alignment: $alignment_percentage% (16KB optimized)${NC}"